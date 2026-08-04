/// Compile-time environment configuration.
///
/// Values are injected with `--dart-define-from-file=dart_defines/dev.json`
/// (see SETUP.md). Only publishable values belong here: the Supabase anon key
/// is public by design, protected by Row-Level Security. Service-role keys
/// must NEVER appear in this app.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Every WanderBites table lives in this schema inside the shared project.
  static const supabaseSchema = String.fromEnvironment(
    'SUPABASE_SCHEMA',
    defaultValue: 'wanderbites',
  );

  /// Google Maps SDK key. The map renders a fallback panel until provided.
  static const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// RevenueCat public SDK keys, one per store app. Publishable by design,
  /// same class as the Supabase key above: they identify, never authorize.
  /// Empty key = billing unavailable on that platform (paywall says so
  /// instead of crashing), which is the permanent state on Android until the
  /// Play products exist.
  static const revenueCatIosKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );
  static const revenueCatAndroidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );

  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static bool get hasMapsKey => googleMapsApiKey.isNotEmpty;

  static bool get isProduction => environment == 'production';
}
