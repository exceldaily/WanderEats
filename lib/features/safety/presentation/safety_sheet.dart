import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/wb_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../data/safety_repository.dart';
import '../domain/safety.dart';

/// One entry point for every "report this" and "block this person" flow.
///
/// Deliberately generic over the target so the same sheet serves profiles,
/// recommendations, comments, lists and restaurants. A second, near-identical
/// report dialog per feature is how safety controls drift apart and how one of
/// them quietly ends up missing.
Future<void> showSafetySheet(
  BuildContext context, {
  required ReportTarget target,
  required String targetId,
  String? subjectUserId,
  String? subjectName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SafetySheet(
      target: target,
      targetId: targetId,
      subjectUserId: subjectUserId,
      subjectName: subjectName,
    ),
  );
}

class _SafetySheet extends ConsumerWidget {
  const _SafetySheet({
    required this.target,
    required this.targetId,
    this.subjectUserId,
    this.subjectName,
  });

  final ReportTarget target;
  final String targetId;
  final String? subjectUserId;
  final String? subjectName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Blocking is only meaningful when there is a person behind the content.
    final canBlock = target.isAuthoredByPerson && subjectUserId != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          WbSpacing.md,
          0,
          WbSpacing.md,
          WbSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report'),
              subtitle: Text(
                subjectName == null
                    ? 'Tell us what is wrong with this'
                    : 'Tell us what is wrong',
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await _openReport(context, ref);
              },
            ),
            if (canBlock)
              _BlockTile(
                userId: subjectUserId!,
                name: subjectName,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReport(BuildContext context, WidgetRef ref) async {
    final reasons = target.isAuthoredByPerson
        ? ReportReason.forPerson
        : ReportReason.forRestaurant;

    final reason = await showModalBottomSheet<ReportReason>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                WbSpacing.md,
                0,
                WbSpacing.md,
                WbSpacing.sm,
              ),
              child: Text("What's happening?"),
            ),
            for (final r in reasons)
              ListTile(
                title: Text(r.label),
                onTap: () => Navigator.of(context).pop(r),
              ),
          ],
        ),
      ),
    );
    if (reason == null || !context.mounted) return;

    // Serious categories are submitted immediately. Asking someone to write a
    // paragraph before they can report a threat is a barrier in exactly the
    // moment it should not be one; optional context can follow.
    await _submit(context, ref, reason);
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    ReportReason reason,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(safetyRepositoryProvider)
          .report(target: target, targetId: targetId, reason: reason);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Thanks. Our team will take a look.'),
        ),
      );
    } on AppException {
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not send that report. Try again.')),
      );
    }
  }
}

class _BlockTile extends ConsumerWidget {
  const _BlockTile({required this.userId, this.name});

  final String userId;
  final String? name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(isBlockedProvider(userId)).value ?? false;
    final who = name ?? 'this account';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        blocked ? Icons.person_add_alt_1_outlined : Icons.block,
        color: blocked ? null : Theme.of(context).colorScheme.error,
      ),
      title: Text(blocked ? 'Unblock $who' : 'Block $who'),
      subtitle: Text(
        blocked
            ? 'They will be able to follow and interact with you again'
            : 'They will not be able to follow, message or interact with you',
      ),
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final repo = ref.read(safetyRepositoryProvider);

        if (blocked) {
          try {
            await repo.unblock(userId);
          } on AppException {
            messenger.showSnackBar(
              const SnackBar(content: Text('Could not unblock. Try again.')),
            );
            return;
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Could not unblock. Try again.')),
            );
            return;
          }
          if (!context.mounted) return;
          ref.invalidate(isBlockedProvider(userId));
          ref.invalidate(blockedAccountsProvider);
          Navigator.of(context).pop();
          messenger.showSnackBar(SnackBar(content: Text('Unblocked $who')));
          return;
        }

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Block $who?'),
            // Says what actually happens, including the part people are often
            // surprised by: following stops in both directions.
            content: const Text(
              'They will not be able to follow you or interact with your '
              'recommendations, and you will stop seeing them around the app. '
              'If either of you follows the other, that will be undone.\n\n'
              'They are not told that you blocked them.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Block'),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;

        try {
          await repo.block(userId);
        } on AppException {
          messenger.showSnackBar(
            const SnackBar(content: Text('Could not block. Try again.')),
          );
          return;
        } catch (_) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Could not block. Try again.')),
          );
          return;
        }
        if (!context.mounted) return;
        ref.invalidate(isBlockedProvider(userId));
        ref.invalidate(blockedAccountsProvider);
        Navigator.of(context).pop();
        messenger.showSnackBar(SnackBar(content: Text('Blocked $who')));
      },
    );
  }
}
