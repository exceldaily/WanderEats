import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../app/configuration/env.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../domain/entitlements.dart';
import 'entitlement_service.dart';

/// What came out of a purchase attempt, from the buyer's point of view.
enum PurchaseOutcome {
  /// Store purchase went through AND the server now grants the entitlements.
  granted,

  /// Store purchase went through but the webhook has not landed yet. The user
  /// paid; access follows within moments. Never treat this as failure.
  pendingServerSync,

  /// The user backed out of the store sheet. Not an error, say nothing.
  cancelled,
}

/// Thrown when the store cannot complete a purchase for a real reason
/// (network, payment declined, store outage) - anything except cancellation.
class BillingException implements Exception {
  BillingException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Talks to the stores through RevenueCat.
///
/// Role boundary: this service produces *purchases*, never *access*. Access
/// is whatever `my_entitlements()` says, and that only changes when the
/// RevenueCat webhook writes a store-verified subscription row. That is why
/// [purchase] ends by polling the server instead of trusting the
/// CustomerInfo the SDK hands back locally.
class BillingService {
  BillingService(this._ref);

  final Ref _ref;

  static bool _configured = false;

  static String get _apiKey {
    if (Platform.isIOS) return Env.revenueCatIosKey;
    if (Platform.isAndroid) return Env.revenueCatAndroidKey;
    return '';
  }

  /// False when this platform has no RevenueCat key configured. The paywall
  /// shows an explanatory state; nothing else should ever call purchase.
  static bool get isAvailable => _apiKey.isNotEmpty;

  /// Configures the SDK (once) and pins its identity to the Supabase user id.
  ///
  /// The webhook maps events to users through `app_user_id`, so this MUST be
  /// the Supabase uuid - an anonymous RevenueCat id would make the webhook
  /// drop the event (deliberately) and the purchase would never grant.
  Future<void> _ensureReady() async {
    if (!isAvailable) {
      throw BillingException('Purchases are not available on this device yet.');
    }
    final session = _ref.read(sessionProvider);
    if (session == null) {
      throw BillingException('Sign in to subscribe.');
    }
    final uid = session.user.id;
    if (!_configured) {
      await Purchases.configure(
        PurchasesConfiguration(_apiKey)..appUserID = uid,
      );
      _configured = true;
      return;
    }
    // Already configured (possibly for a previous account this app run):
    // logIn is a cheap no-op for the same uid and an identity switch for a
    // different one, so calling it unconditionally is the simplest correct
    // thing.
    await Purchases.logIn(uid);
  }

  /// The offering the paywall renders, as configured in RevenueCat
  /// ("default": Monthly + Annual packages).
  Future<Offering?> currentOffering() async {
    await _ensureReady();
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } on PlatformException catch (e) {
      throw BillingException(_describe(e));
    }
  }

  /// Buys [package], then waits for the server to acknowledge.
  Future<PurchaseOutcome> purchase(Package package) async {
    await _ensureReady();
    try {
      await Purchases.purchase(PurchaseParams.package(package));
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      throw BillingException(_describe(e));
    }
    return _afterStoreSuccess();
  }

  /// Re-syncs previous purchases (reinstall, new device), then waits for the
  /// server the same way a fresh purchase does.
  Future<PurchaseOutcome> restore() async {
    await _ensureReady();
    try {
      await Purchases.restorePurchases();
    } on PlatformException catch (e) {
      throw BillingException(_describe(e));
    }
    return _afterStoreSuccess();
  }

  Future<PurchaseOutcome> _afterStoreSuccess() async {
    final granted = await pollUntilGranted(
      () => _ref.read(entitlementServiceProvider).current(),
    );
    _ref.invalidate(entitlementsProvider);
    return granted ? PurchaseOutcome.granted : PurchaseOutcome.pendingServerSync;
  }

  String _describe(PlatformException e) {
    switch (PurchasesErrorHelper.getErrorCode(e)) {
      case PurchasesErrorCode.networkError:
      case PurchasesErrorCode.offlineConnectionError:
        return 'No connection. Check your network and try again.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchases are not allowed on this device.';
      case PurchasesErrorCode.paymentPendingError:
        return 'Your payment is pending approval.';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return 'You already have this subscription. Try Restore purchases.';
      case PurchasesErrorCode.storeProblemError:
        return 'The store had a problem. Try again in a moment.';
      default:
        // The code name is deliberately included: "could not be completed"
        // alone has already cost a debugging round-trip, and during testing
        // the person reading this IS the developer.
        return 'The purchase could not be completed '
            '(${PurchasesErrorHelper.getErrorCode(e).name}: '
            '${e.message ?? 'no detail'}). Try again.';
    }
  }
}

/// Polls [fetch] until it reports premium or [attempts] run out.
///
/// Exists as a standalone function so the timing logic is testable without
/// the store SDK. The webhook usually lands within a second or two of the
/// store sheet closing; 15 x 2s covers a slow retry without trapping the
/// user on a spinner forever.
Future<bool> pollUntilGranted(
  Future<Entitlements> Function() fetch, {
  int attempts = 15,
  Duration interval = const Duration(seconds: 2),
  Future<void> Function(Duration) delay = Future.delayed,
}) async {
  for (var i = 0; i < attempts; i++) {
    try {
      if ((await fetch()).isPremium) return true;
    } catch (_) {
      // A transient fetch error must not abort the wait: the purchase
      // already happened, all we are doing is watching for it to register.
    }
    if (i < attempts - 1) await delay(interval);
  }
  return false;
}

final billingServiceProvider = Provider<BillingService>(BillingService.new);
