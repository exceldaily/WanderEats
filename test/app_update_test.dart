import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/core/services/update/app_update.dart';

void main() {
  group('resolveUpdate', () {
    test('a build matching the server prompts for nothing', () {
      final status = resolveUpdate(
        currentBuild: 17,
        latestBuild: 17,
        minSupportedBuild: 0,
      );
      expect(status.urgency, UpdateUrgency.none);
      expect(status.isAvailable, isFalse);
    });

    test('a newer build on the server offers a dismissible update', () {
      final status = resolveUpdate(
        currentBuild: 15,
        latestBuild: 17,
        minSupportedBuild: 0,
      );
      expect(status.urgency, UpdateUrgency.optional);
      expect(status.isBlocking, isFalse);
      expect(status.latestBuild, 17);
    });

    test('below the supported floor the prompt blocks', () {
      final status = resolveUpdate(
        currentBuild: 12,
        latestBuild: 17,
        minSupportedBuild: 14,
      );
      expect(status.urgency, UpdateUrgency.required);
      expect(status.isBlocking, isTrue);
    });

    test('a floor breach blocks even when no newer build is advertised', () {
      // Belt and braces: latest_build could lag behind min_supported_build if
      // the rows are edited out of order.
      final status = resolveUpdate(
        currentBuild: 10,
        latestBuild: 10,
        minSupportedBuild: 14,
      );
      expect(status.urgency, UpdateUrgency.required);
    });

    test('a missing server value never prompts', () {
      final status = resolveUpdate(
        currentBuild: 17,
        latestBuild: null,
        minSupportedBuild: null,
      );
      expect(status.urgency, UpdateUrgency.none);
    });

    test('a build ahead of the server is left alone', () {
      // Local and TestFlight builds routinely run ahead of what the store has
      // published; nagging them would be wrong every time.
      final status = resolveUpdate(
        currentBuild: 20,
        latestBuild: 17,
        minSupportedBuild: 0,
      );
      expect(status.urgency, UpdateUrgency.none);
      expect(status.isAvailable, isFalse);
    });
  });
}
