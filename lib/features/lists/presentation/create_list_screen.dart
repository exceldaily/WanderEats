import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/analytics/analytics_service.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/list_repository.dart';

class CreateListScreen extends ConsumerStatefulWidget {
  const CreateListScreen({super.key});

  @override
  ConsumerState<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends ConsumerState<CreateListScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _visibility = 'public';
  bool _collaborative = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Give the list a title.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final list = await ref
          .read(listRepositoryProvider)
          .create(
            ownerId: session.user.id,
            title: _title.text.trim(),
            description: _description.text.trim(),
            visibility: _visibility,
            isCollaborative: _collaborative,
          );
      unawaited(ref.read(analyticsProvider).listCreated(listId: list.id));
      if (mounted) {
        context.pushReplacementNamed(
          Routes.list,
          pathParameters: {'id': list.id},
        );
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('New list')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(WbSpacing.md),
          children: [
            TextField(
              controller: _title,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Best Pizza in New York',
              ),
            ),
            const SizedBox(height: WbSpacing.sm),
            TextField(
              controller: _description,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What ties these places together?',
              ),
            ),
            const SizedBox(height: WbSpacing.md),
            Text('Who can see it?', style: theme.textTheme.labelLarge),
            const SizedBox(height: WbSpacing.xs),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'public',
                  label: Text('Public'),
                  icon: Icon(Icons.public),
                ),
                ButtonSegment(
                  value: 'private',
                  label: Text('Just me'),
                  icon: Icon(Icons.lock_outline),
                ),
              ],
              selected: {_visibility},
              onSelectionChanged: (s) => setState(() => _visibility = s.first),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Collaborative'),
              subtitle: const Text('Invite friends to add places to this list'),
              value: _collaborative,
              onChanged: (v) => setState(() => _collaborative = v),
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: WbSpacing.md),
            FilledButton(
              onPressed: _busy ? null : _create,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create list'),
            ),
          ],
        ),
      ),
    );
  }
}
