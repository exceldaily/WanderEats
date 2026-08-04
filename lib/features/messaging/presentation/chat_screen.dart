import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../data/messaging_repository.dart';
import '../domain/messaging_models.dart';

/// One conversation. Polls while open (this shared Supabase project has no
/// realtime publication, and a 5s poll on an open chat is indistinguishable
/// in practice); sends are confirmed by a refetch rather than trusted
/// optimistically, so what you see is what the server accepted.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId, this.peerName});

  final String conversationId;
  final String? peerName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  MessagingRepository get _repo => ref.read(messagingRepositoryProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_refresh(markRead: true));
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool markRead = false}) async {
    try {
      final page = await _repo.messages(widget.conversationId);
      if (!mounted) return;
      final hadNew =
          _messages.isEmpty || (page.isNotEmpty && page.first.id != _messages.first.id);
      setState(() {
        _messages = page;
        _loading = false;
        _error = null;
      });
      if (markRead || hadNew) {
        unawaited(_repo.markRead(widget.conversationId));
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _messages.isEmpty ? e.message : null;
      });
    }
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _repo.sendMessage(widget.conversationId, body);
      _input.clear();
      await _refresh();
      if (_scroll.hasClients) {
        // reverse:true list - offset 0 is the newest message.
        _scroll.jumpTo(0);
      }
    } on DmException catch (e) {
      if (!mounted) return;
      final availability = e.availability;
      if (availability is DmDenied &&
          availability.denial.canBeSolvedByUpgrading) {
        // The one denial an upgrade fixes. Everything else - age, blocks,
        // suspension - must never route to the paywall.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            action: SnackBarAction(
              label: 'Go Premium',
              onPressed: () => context.pushNamed(Routes.premium),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmDelete(ChatMessage m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('It will disappear for both of you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.deleteMessage(m.id);
      await _refresh();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(sessionProvider)?.user.id;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName ?? 'Conversation')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(WbSpacing.xl),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      reverse: true,
                      padding: const EdgeInsets.all(WbSpacing.md),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        final mine = m.senderId == myId;
                        return _Bubble(
                          message: m,
                          mine: mine,
                          onLongPress: mine ? () => _confirmDelete(m) : null,
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WbSpacing.md,
                WbSpacing.sm,
                WbSpacing.sm,
                WbSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Send',
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine, this.onLongPress});

  final ChatMessage message;
  final bool mine;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = TimeOfDay.fromDateTime(message.createdAt).format(context);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.only(bottom: WbSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: WbSpacing.md,
            vertical: WbSpacing.sm,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.75,
          ),
          decoration: BoxDecoration(
            color: mine ? scheme.primaryContainer : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(WbRadius.card),
              topRight: const Radius.circular(WbRadius.card),
              bottomLeft: Radius.circular(mine ? WbRadius.card : 4),
              bottomRight: Radius.circular(mine ? 4 : WbRadius.card),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message.body),
              const SizedBox(height: 2),
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
