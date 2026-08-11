import 'package:flutter/material.dart';

/// WanderBites design tokens.
///
/// Brand direction: curious, adventurous, trustworthy, premium, warm.
/// Deep voyage teal carries trust and travel; ember coral is the appetite
/// accent, used sparingly. Warm off-whites keep it inviting, never clinical.
abstract final class WbColors {
  // Primary: Voyage teal
  static const voyage = Color(0xFF0E4F4A);
  static const voyageLight = Color(0xFF3B7A73);

  // Accent: Ember coral (appetite, saves, CTAs)
  static const ember = Color(0xFFE4593B);
  static const emberSoft = Color(0xFFFBE9E3);

  // Warm neutrals
  static const cream = Color(0xFFFAF6F0);
  static const sand = Color(0xFFF0E9DE);
  static const ink = Color(0xFF1E211F);

  // Dark theme surfaces (deep charcoal with a green undertone)
  static const nightSurface = Color(0xFF121614);
  static const nightCard = Color(0xFF1C221F);
  static const nightBorder = Color(0xFF2C332F);

  // Semantic
  static const success = Color(0xFF2E7D4F);
  static const warning = Color(0xFFC98A16);
  static const danger = Color(0xFFB3402A);

  // Trending accent (map pins use BitmapDescriptor hues, not these tokens)
  static const markerTrending = Color(0xFFC98A16);
}

abstract final class WbSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class WbRadius {
  static const double chip = 8;
  static const double card = 16;
  static const double sheet = 24;
  static const double pill = 999;
}

abstract final class WbElevation {
  static const double card = 1;
  static const double raisedCard = 3;
  static const double sheet = 8;
}

/// Minimum touch target per accessibility requirements.
const double kWbMinTouchTarget = 48;
