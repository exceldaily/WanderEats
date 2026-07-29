import 'package:flutter/material.dart';

import 'wb_tokens.dart';

/// Material 3 themes built from the WanderBites token set.
abstract final class WbTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: WbColors.voyage,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? WbColors.voyageLight : WbColors.voyage,
          secondary: WbColors.ember,
          surface: isDark ? WbColors.nightSurface : WbColors.cream,
          surfaceContainerLow: isDark ? WbColors.nightCard : Colors.white,
          surfaceContainerHighest: isDark
              ? WbColors.nightBorder
              : WbColors.sand,
          error: WbColors.danger,
        );

    final textTheme = Typography.material2021(platform: TargetPlatform.android)
        .englishLike
        .apply(
          bodyColor: isDark ? WbColors.cream : WbColors.ink,
          displayColor: isDark ? WbColors.cream : WbColors.ink,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: WbElevation.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WbRadius.card),
        ),
        color: scheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WbRadius.chip),
        ),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(kWbMinTouchTarget, kWbMinTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WbRadius.pill),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(kWbMinTouchTarget, kWbMinTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WbRadius.pill),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WbRadius.card),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: WbSpacing.md,
          vertical: WbSpacing.md,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(WbRadius.sheet),
          ),
        ),
        showDragHandle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 68,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WbRadius.card),
        ),
      ),
    );
  }
}
