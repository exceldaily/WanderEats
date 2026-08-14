import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../networking/supabase_provider.dart';
import 'app_update.dart';

/// Asks the server whether a newer build exists.
///
/// The version floor lives in `app_settings` rather than in the binary, so
/// announcing a release is a database edit, not another release. Every failure
/// path resolves to "up to date": a version check that breaks must never stand
/// between the user and the app.
class UpdateService {
  UpdateService(this._ref);

  final Ref _ref;

  Future<AppUpdateStatus> check() async {
    final currentBuild = await _currentBuild();
    if (currentBuild == null) return const AppUpdateStatus.upToDate(0);

    try {
      final rows = await _ref
          .read(wbSchemaProvider)
          .from('app_settings')
          .select('key, value')
          .inFilter('key', const [
            'latest_build',
            'min_supported_build',
            'update_message',
          ]);

      final settings = <String, Object?>{
        for (final row in rows.cast<Map<String, dynamic>>())
          row['key'] as String: row['value'],
      };

      final status = resolveUpdate(
        currentBuild: currentBuild,
        latestBuild: _asInt(settings['latest_build']),
        minSupportedBuild: _asInt(settings['min_supported_build']),
      );

      final message = settings['update_message'];
      if (!status.isAvailable || message is! String || message.isEmpty) {
        return status;
      }
      return AppUpdateStatus(
        urgency: status.urgency,
        currentBuild: status.currentBuild,
        latestBuild: status.latestBuild,
        message: message,
      );
    } catch (_) {
      return AppUpdateStatus.upToDate(currentBuild);
    }
  }

  Future<int?> _currentBuild() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return int.tryParse(info.buildNumber);
    } catch (_) {
      return null;
    }
  }

  /// The setting is jsonb, so a value can arrive as a number or as a string
  /// depending on how it was written.
  static int? _asInt(Object? value) => switch (value) {
    final int v => v,
    final String v => int.tryParse(v),
    _ => null,
  };
}

final updateServiceProvider = Provider<UpdateService>(UpdateService.new);

/// The launch check. Read once per app start; Settings refreshes it manually.
final updateStatusProvider = FutureProvider<AppUpdateStatus>(
  (ref) => ref.watch(updateServiceProvider).check(),
);
