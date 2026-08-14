import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../links/safe_link.dart';
import 'app_update.dart';
import 'update_service.dart';

/// Offers the update, and sends the user to the store.
///
/// Blocking prompts (a build below the supported floor) cannot be dismissed by
/// back gesture or barrier tap; optional ones can be waved away and will not
/// reappear until the next launch.
abstract final class UpdatePrompt {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    AppUpdateStatus status,
  ) async {
    final blocking = status.isBlocking;

    await showDialog<void>(
      context: context,
      barrierDismissible: !blocking,
      builder: (dialogContext) => PopScope(
        canPop: !blocking,
        child: AlertDialog(
          title: Text(blocking ? 'Update required' : 'Update available'),
          content: Text(
            status.message ??
                (blocking
                    ? 'This version of WanderBites is too old to keep working '
                          'properly. Update to carry on.'
                    : 'A newer version of WanderBites is ready. Updating takes '
                          'a moment and keeps everything working smoothly.'),
          ),
          actions: [
            if (!blocking)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Later'),
              ),
            FilledButton(
              onPressed: () async {
                final rejection = await SafeLink.open(StoreListing.primary);
                // market:// only resolves where the Play app exists; fall back
                // to the web listing rather than failing silently.
                if (rejection != null) {
                  await SafeLink.open(StoreListing.fallback);
                }
                if (!blocking && dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Runs the launch check once and shows the prompt if needed.
///
/// Wraps the app shell rather than living in a screen, so it survives tab
/// switches and cannot fire twice.
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(updateStatusProvider, (_, next) {
      final status = next.value;
      if (_handled || status == null || !status.isAvailable) return;
      _handled = true;
      // The check resolves mid-build; defer so the dialog does not open
      // during a frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) UpdatePrompt.show(context, ref, status);
      });
    });

    return widget.child;
  }
}
