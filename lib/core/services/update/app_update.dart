import 'dart:io' show Platform;

/// How badly the running build is out of date.
enum UpdateUrgency {
  /// Nothing to do.
  none,

  /// A newer build exists. The prompt can be dismissed.
  optional,

  /// This build is below the supported floor and cannot be trusted against
  /// the current backend. The prompt cannot be dismissed.
  required,
}

/// The result of comparing this build against what the server expects.
class AppUpdateStatus {
  const AppUpdateStatus({
    required this.urgency,
    required this.currentBuild,
    required this.latestBuild,
    this.message,
  });

  const AppUpdateStatus.upToDate(this.currentBuild)
    : urgency = UpdateUrgency.none,
      latestBuild = currentBuild,
      message = null;

  final UpdateUrgency urgency;
  final int currentBuild;
  final int latestBuild;

  /// Optional note from the server, shown instead of the generic line when a
  /// particular release needs explaining.
  final String? message;

  bool get isAvailable => urgency != UpdateUrgency.none;
  bool get isBlocking => urgency == UpdateUrgency.required;
}

/// Pure comparison, kept free of plugins so it can be tested directly.
///
/// Fails safe in both directions: a missing or unparseable server value means
/// no prompt at all, and a build *ahead* of the server (a local or TestFlight
/// build) is never nagged. Both matter because this runs before the user has
/// done anything, and a false "update required" would be a hard lockout.
AppUpdateStatus resolveUpdate({
  required int currentBuild,
  required int? latestBuild,
  required int? minSupportedBuild,
}) {
  if (latestBuild == null || latestBuild <= currentBuild) {
    if (minSupportedBuild != null && currentBuild < minSupportedBuild) {
      return AppUpdateStatus(
        urgency: UpdateUrgency.required,
        currentBuild: currentBuild,
        latestBuild: latestBuild ?? minSupportedBuild,
      );
    }
    return AppUpdateStatus.upToDate(currentBuild);
  }

  final blocking = minSupportedBuild != null && currentBuild < minSupportedBuild;
  return AppUpdateStatus(
    urgency: blocking ? UpdateUrgency.required : UpdateUrgency.optional,
    currentBuild: currentBuild,
    latestBuild: latestBuild,
  );
}

/// Where "Update" sends the user.
///
/// Neither platform allows an app to update itself silently: Apple forbids it
/// outright, and Android can only hand off to Play. So the honest destination
/// is the store listing.
abstract final class StoreListing {
  static const _androidPackage = 'com.wanderbites.app';
  static const _appleId = '6796729743';

  /// Prefers the Play app's own scheme so Android opens the store directly
  /// rather than bouncing through a browser.
  static String get primary => Platform.isIOS
      ? 'https://apps.apple.com/app/id$_appleId'
      : 'market://details?id=$_androidPackage';

  /// Used when [primary] cannot be handled - a device without the Play app,
  /// or a sideloaded build.
  static String get fallback => Platform.isIOS
      ? 'https://apps.apple.com/app/id$_appleId'
      : 'https://play.google.com/store/apps/details?id=$_androidPackage';
}
