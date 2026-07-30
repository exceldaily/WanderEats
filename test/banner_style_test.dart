import 'package:flutter_test/flutter_test.dart';
import 'package:wanderbites/features/profile/presentation/widgets/profile_header.dart';

void main() {
  group('parseBannerStyle', () {
    test('splits design and color', () {
      final r = parseBannerStyle('bbq:ember');
      expect(r.design, 'bbq');
      expect(r.color, 'ember');
    });

    test('falls back to classic for a bare color', () {
      // Every row is backfilled by migration 0020, so this is a defensive
      // path rather than an expected input - it must not crash a profile
      // page over a stray value.
      final r = parseBannerStyle('voyage');
      expect(r.design, 'classic');
      expect(r.color, 'voyage');
    });
  });

  test('composeBannerStyle round-trips through parseBannerStyle', () {
    for (final design in kBannerDesigns) {
      for (final color in kBannerColors) {
        final composed = composeBannerStyle(design, color);
        final parsed = parseBannerStyle(composed);
        expect(parsed.design, design);
        expect(parsed.color, color);
      }
    }
  });

  test('every design has a display label', () {
    for (final design in kBannerDesigns) {
      expect(bannerDesignLabel(design), isNotEmpty);
    }
  });
}
