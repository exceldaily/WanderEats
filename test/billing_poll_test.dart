import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/features/premium/data/billing_service.dart';
import 'package:wanderbites/features/premium/domain/entitlements.dart';

void main() {
  // The store said "paid"; pollUntilGranted watches for the webhook-written
  // server truth to catch up. These tests pin down the behaviours a paying
  // user depends on: patience with latency, immunity to transient fetch
  // errors, and refusing to spin forever.
  group('pollUntilGranted', () {
    final premium = Entitlements.fromCodes(const ['direct_messaging']);
    const none = Entitlements.none();

    Future<void> noDelay(Duration _) async {}

    test('returns true immediately when already granted', () async {
      var calls = 0;
      final granted = await pollUntilGranted(() async {
        calls++;
        return premium;
      }, delay: noDelay);
      expect(granted, isTrue);
      expect(calls, 1, reason: 'no needless extra fetches once granted');
    });

    test('keeps polling until the webhook lands', () async {
      var calls = 0;
      final granted = await pollUntilGranted(() async {
        calls++;
        return calls < 4 ? none : premium;
      }, delay: noDelay);
      expect(granted, isTrue);
      expect(calls, 4);
    });

    test('a transient fetch error does not abort the wait', () async {
      // The purchase already happened; a flaky network moment while watching
      // for it to register must not surface as a failed purchase.
      var calls = 0;
      final granted = await pollUntilGranted(() async {
        calls++;
        if (calls == 1) throw Exception('network blip');
        return premium;
      }, delay: noDelay);
      expect(granted, isTrue);
    });

    test('gives up after the attempt budget instead of spinning forever', () async {
      var calls = 0;
      final granted = await pollUntilGranted(() async {
        calls++;
        return none;
      }, attempts: 5, delay: noDelay);
      expect(granted, isFalse);
      expect(calls, 5);
    });

    test('does not delay after the final attempt', () async {
      var delays = 0;
      await pollUntilGranted(
        () async => none,
        attempts: 3,
        delay: (_) async => delays++,
      );
      expect(delays, 2, reason: 'n attempts need only n-1 waits between them');
    });
  });
}
