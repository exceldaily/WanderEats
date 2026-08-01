// RevenueCat -> wanderbites.subscriptions
//
// RevenueCat validates the receipt with Apple or Google and then tells us what
// happened. This function is the only writer of subscription state: the client
// cannot write those tables at all, which is what makes has_entitlement()
// meaningful rather than a suggestion.
//
// Auth: RevenueCat sends whatever Authorization header you configure on the
// webhook. We compare it against REVENUECAT_WEBHOOK_SECRET in constant time.
// verify_jwt is off because RevenueCat cannot mint a Supabase JWT; this header
// is the entire authentication, so it must not be guessable and must not leak.
//
// User mapping: the app sets RevenueCat's app_user_id to the Supabase user id
// at sign-in, so app_user_id IS our uuid. Anything else is rejected rather than
// guessed at, because attaching a subscription to the wrong account is worse
// than dropping the event and retrying.

import { createClient } from 'jsr:@supabase/supabase-js@2';

/** Compares two strings without leaking length or position through timing. */
function safeEqual(a: string, b: string): boolean {
  const ba = new TextEncoder().encode(a);
  const bb = new TextEncoder().encode(b);
  if (ba.length !== bb.length) return false;
  let diff = 0;
  for (let i = 0; i < ba.length; i++) diff |= ba[i] ^ bb[i];
  return diff === 0;
}

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * RevenueCat event type -> our subscription status.
 *
 * Deliberately explicit rather than a catch-all: an event we do not recognise
 * should be logged and ignored, not silently mapped to 'active'.
 */
function statusFor(eventType: string, expiresAtMs: number | null): string | null {
  switch (eventType) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
    case 'PRODUCT_CHANGE':
    case 'UNCANCELLATION':
    case 'SUBSCRIPTION_EXTENDED':
      return 'active';
    case 'CANCELLATION':
      // The user turned off auto-renew. They keep access until the period ends,
      // so this is not an immediate revocation.
      return expiresAtMs && expiresAtMs > Date.now() ? 'active' : 'cancelled';
    case 'BILLING_ISSUE':
      return 'in_grace_period';
    case 'EXPIRATION':
      return 'expired';
    case 'REFUND':
    case 'REFUND_REVERSED':
      return eventType === 'REFUND' ? 'refunded' : 'active';
    case 'SUBSCRIPTION_PAUSED':
      return 'paused';
    // TRANSFER and NON_RENEWING_PURCHASE need their own handling before they
    // can be trusted; returning null means "record nothing" rather than "guess".
    default:
      return null;
  }
}

function storeFor(raw: string | undefined): string | null {
  switch (raw) {
    case 'APP_STORE':
    case 'MAC_APP_STORE':
      return 'app_store';
    case 'PLAY_STORE':
      return 'play_store';
    case 'PROMOTIONAL':
      return 'promotional';
    default:
      return raw ? raw.toLowerCase() : null;
  }
}

Deno.serve(async (req) => {
  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { 'Content-Type': 'application/json' },
    });

  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  const expected = Deno.env.get('REVENUECAT_WEBHOOK_SECRET');
  if (!expected) {
    // Fail closed. An unconfigured secret must never mean "accept everything".
    console.error('REVENUECAT_WEBHOOK_SECRET is not set; rejecting');
    return json({ error: 'not_configured' }, 503);
  }

  const provided = req.headers.get('Authorization') ?? '';
  if (!safeEqual(provided, expected)) {
    // Deliberately vague: a probing caller learns nothing about the secret.
    return json({ error: 'unauthorized' }, 401);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'invalid_json' }, 400);
  }

  const event = (body.event ?? {}) as Record<string, unknown>;
  const eventType = String(event.type ?? '');
  const appUserId = String(event.app_user_id ?? '');
  const productId = String(event.product_id ?? '');

  if (!UUID_RE.test(appUserId)) {
    // Anonymous RevenueCat ids ($RCAnonymousID:...) arrive when a purchase
    // happened before sign-in. Acknowledge so RevenueCat stops retrying, but
    // record nothing: guessing an owner is worse than missing the event, and
    // the app re-syncs entitlements on next launch anyway.
    console.warn('skipping event for non-uuid app_user_id', eventType);
    return json({ ok: true, skipped: 'unmapped_user' });
  }
  if (!productId) return json({ ok: true, skipped: 'no_product' });

  const expiresAtMs = typeof event.expiration_at_ms === 'number'
    ? event.expiration_at_ms
    : null;
  const status = statusFor(eventType, expiresAtMs);
  if (status === null) {
    console.warn('unhandled RevenueCat event type', eventType);
    return json({ ok: true, skipped: 'unhandled_event_type' });
  }

  const purchasedAtMs = typeof event.purchased_at_ms === 'number'
    ? event.purchased_at_ms
    : null;

  const db = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { db: { schema: 'wanderbites' } },
  );

  const { data, error } = await db.rpc('record_subscription_event', {
    p_user_id: appUserId,
    p_product_id: productId,
    p_status: status,
    p_expires_at: expiresAtMs ? new Date(expiresAtMs).toISOString() : null,
    p_store: storeFor(event.store as string | undefined),
    p_period_type: event.period_type
      ? String(event.period_type).toLowerCase()
      : null,
    p_environment: event.environment === 'SANDBOX' ? 'sandbox' : 'production',
    p_auto_renew: eventType !== 'CANCELLATION' && status === 'active',
    p_provider_user_id: appUserId,
    p_purchased_at: purchasedAtMs
      ? new Date(purchasedAtMs).toISOString()
      : null,
    // Kept for support and dispute handling. Contains no card details;
    // RevenueCat never sends them.
    p_raw: event,
  });

  if (error) {
    // A 5xx makes RevenueCat retry, which is what we want for a transient
    // database problem. Never swallow this into a 200.
    console.error('record_subscription_event failed', error.message);
    return json({ error: 'record_failed', detail: error.message }, 500);
  }

  return json({ ok: true, subscription_id: data, status });
});
