import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/configuration/env.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/analytics/analytics_service.dart';
import '../../../core/utils/plural.dart';
import '../../../core/widgets/wb_states.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../restaurants/presentation/widgets/restaurant_picker_sheet.dart';
import '../data/list_repository.dart';
import '../domain/food_list.dart';

final listProvider = FutureProvider.autoDispose.family<FoodList, String>(
  (ref, id) => ref.watch(listRepositoryProvider).fetchList(id),
);

final listPlacesProvider = FutureProvider.autoDispose
    .family<List<ListPlace>, String>(
      (ref, id) => ref.watch(listRepositoryProvider).places(id),
    );

final listMetaProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) {
      final myId = ref.watch(sessionProvider)?.user.id;
      return ref.watch(listRepositoryProvider).listMeta(id, myId);
    });

final listCommentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
      (ref, id) => ref.watch(listRepositoryProvider).comments(id),
    );

/// A list like a playlist: cover, meta, ordered places, map view, comments.
class ListDetailsScreen extends ConsumerStatefulWidget {
  const ListDetailsScreen({super.key, required this.listId});

  final String listId;

  @override
  ConsumerState<ListDetailsScreen> createState() => _ListDetailsScreenState();
}

class _ListDetailsScreenState extends ConsumerState<ListDetailsScreen> {
  bool _mapView = false;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _rename(FoodList list) async {
    final title = TextEditingController(text: list.title);
    final description = TextEditingController(text: list.description ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename list'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              autofocus: true,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: description,
              maxLength: 200,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final newTitle = title.text.trim();
    title.dispose();
    final newDescription = description.text.trim();
    description.dispose();
    if (saved != true || newTitle.isEmpty) return;

    try {
      await ref.read(listRepositoryProvider).update(widget.listId, {
        'title': newTitle,
        'description': newDescription.isEmpty ? null : newDescription,
      });
      ref.invalidate(listProvider(widget.listId));
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmDelete(FoodList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${list.title}"?'),
        content: const Text(
          'The list is removed for everyone following it. The restaurants '
          'themselves are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(listRepositoryProvider).softDelete(widget.listId);
      if (mounted) context.pop();
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = ref.watch(listProvider(widget.listId));
    final myId = ref.watch(sessionProvider)?.user.id;

    return Scaffold(
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => WbErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(listProvider(widget.listId)),
        ),
        data: (l) {
          final isOwner = myId == l.ownerId;
          final places = ref.watch(listPlacesProvider(widget.listId));
          final meta = ref.watch(listMetaProvider(widget.listId)).value;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                actions: [
                  IconButton(
                    tooltip: 'Share',
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      unawaited(
                        ref
                            .read(analyticsProvider)
                            .shareInitiated(contentType: 'list', id: l.id),
                      );
                      unawaited(
                        SharePlus.instance.share(
                          ShareParams(text: '"${l.title}" on WanderBites'),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: _mapView ? 'List view' : 'Map view',
                    icon: Icon(_mapView ? Icons.list : Icons.map_outlined),
                    onPressed: () => setState(() => _mapView = !_mapView),
                  ),
                  // Owners could add and reorder places but never rename or
                  // delete the list itself, which left create as a one-way
                  // door. Both repository calls already existed.
                  if (isOwner)
                    PopupMenuButton<String>(
                      tooltip: 'List options',
                      onSelected: (value) async {
                        if (value == 'rename') await _rename(l);
                        if (value == 'delete') await _confirmDelete(l);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'rename',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Rename list'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Delete list'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    l.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  background: l.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: l.coverUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(color: WbColors.voyage),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(WbSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (l.description != null)
                        Text(l.description!, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: WbSpacing.sm),
                      Text(
                        [
                          'by @${l.owner?['username'] ?? 'unknown'}',
                          places.value == null ? '- places' : countOf(places.value!.length, 'place'),
                          meta?['followers'] == null ? '- followers' : countOfDynamic(meta!['followers'], 'follower'),
                          '${meta?['likes'] ?? '-'} likes',
                          if (l.isCollaborative) 'collaborative',
                          if (l.visibility == 'private') 'private',
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: WbSpacing.md),
                      Row(
                        children: [
                          if (!isOwner)
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: myId == null
                                    ? null
                                    : () async {
                                        final follows =
                                            meta?['i_follow'] == true;
                                        final repo = ref.read(
                                          listRepositoryProvider,
                                        );
                                        if (follows) {
                                          await repo.unfollowList(myId, l.id);
                                        } else {
                                          await repo.followList(myId, l.id);
                                          unawaited(
                                            ref
                                                .read(analyticsProvider)
                                                .listFollowed(listId: l.id),
                                          );
                                        }
                                        ref.invalidate(
                                          listMetaProvider(widget.listId),
                                        );
                                      },
                                icon: Icon(
                                  meta?['i_follow'] == true
                                      ? Icons.check
                                      : Icons.add,
                                ),
                                label: Text(
                                  meta?['i_follow'] == true
                                      ? 'Following'
                                      : 'Follow list',
                                ),
                              ),
                            ),
                          if (!isOwner) const SizedBox(width: WbSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: myId == null
                                  ? null
                                  : () async {
                                      await ref
                                          .read(listRepositoryProvider)
                                          .toggleLike(
                                            myId,
                                            l.id,
                                            meta?['i_like'] != true,
                                          );
                                      ref.invalidate(
                                        listMetaProvider(widget.listId),
                                      );
                                    },
                              icon: Icon(
                                meta?['i_like'] == true
                                    ? Icons.favorite
                                    : Icons.favorite_outline,
                              ),
                              label: Text('${meta?['likes'] ?? 0}'),
                            ),
                          ),
                          if (isOwner || l.isCollaborative) ...[
                            const SizedBox(width: WbSpacing.sm),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final picked = await showRestaurantPicker(
                                    context,
                                  );
                                  if (picked == null || myId == null) return;
                                  try {
                                    await ref
                                        .read(listRepositoryProvider)
                                        .addRestaurant(
                                          listId: l.id,
                                          restaurantId: picked.id,
                                          addedBy: myId,
                                        );
                                    ref.invalidate(
                                      listPlacesProvider(widget.listId),
                                    );
                                  } on AppException catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(e.message)),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add place'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Places: map or ordered list
              places.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(WbSpacing.md),
                    child: WbSkeleton(height: 160),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(WbSpacing.md),
                    child: Text('Could not load places: $e'),
                  ),
                ),
                data: (items) => _mapView
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: WbSpacing.md,
                          ),
                          child: _ListMap(items: items),
                        ),
                      )
                    : items.isEmpty
                    ? const SliverToBoxAdapter(
                        child: WbEmptyState(
                          icon: Icons.playlist_add,
                          title: 'Nothing here yet',
                          message: 'Add the first place.',
                        ),
                      )
                    : isOwner
                    ? _reorderableEntries(items)
                    : _staticEntries(items),
              ),
              // Comments
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(WbSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Text(
                        'Comments',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: WbSpacing.sm),
                      if (myId != null)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _comment,
                                maxLength: 500,
                                decoration: const InputDecoration(
                                  hintText: 'Add a comment',
                                  counterText: '',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () async {
                                final body = _comment.text.trim();
                                if (body.isEmpty) return;
                                await ref
                                    .read(listRepositoryProvider)
                                    .addComment(myId, l.id, body);
                                _comment.clear();
                                ref.invalidate(
                                  listCommentsProvider(widget.listId),
                                );
                              },
                            ),
                          ],
                        ),
                      ...?ref
                          .watch(listCommentsProvider(widget.listId))
                          .value
                          ?.map(
                            (c) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.person_outline),
                              title: Text(
                                '@${(c['profiles'] as Map?)?['username'] ?? ''}',
                              ),
                              subtitle: Text(c['body'] as String),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: WbSpacing.xl)),
            ],
          );
        },
      ),
    );
  }

  Widget _staticEntries(List<ListPlace> items) {
    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => _EntryTile(place: items[i], index: i),
    );
  }

  Widget _reorderableEntries(List<ListPlace> items) {
    return SliverToBoxAdapter(
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: true,
        itemCount: items.length,
        onReorderItem: (oldIndex, newIndex) async {
          // onReorderItem already adjusts newIndex for the removed item.
          final reordered = [...items];
          final moved = reordered.removeAt(oldIndex);
          reordered.insert(newIndex, moved);
          await ref
              .read(listRepositoryProvider)
              .reorder(widget.listId, reordered.map((e) => e.entryId).toList());
          ref.invalidate(listPlacesProvider(widget.listId));
        },
        itemBuilder: (context, i) => KeyedSubtree(
          key: ValueKey(items[i].entryId),
          child: _EntryTile(
            place: items[i],
            index: i,
            onRemove: () async {
              await ref
                  .read(listRepositoryProvider)
                  .removeEntry(items[i].entryId);
              ref.invalidate(listPlacesProvider(widget.listId));
            },
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.place, required this.index, this.onRemove});

  final ListPlace place;
  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(radius: 14, child: Text('${index + 1}')),
      title: Text(place.marker.name),
      subtitle: place.note != null
          ? Text(place.note!)
          : Text(countOf(place.marker.recCount, 'recommendation')),
      trailing: onRemove != null
          ? IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onRemove,
            )
          : const Icon(Icons.chevron_right),
      onTap: () => context.pushNamed(
        Routes.restaurant,
        pathParameters: {'id': place.marker.id},
      ),
    );
  }
}

class _ListMap extends StatelessWidget {
  const _ListMap({required this.items});

  final List<ListPlace> items;

  @override
  Widget build(BuildContext context) {
    if (!Env.hasMapsKey || items.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(WbRadius.card),
        ),
        child: Center(
          child: Text(
            items.isEmpty
                ? 'No places yet'
                : '${countOf(items.length, 'place')} (map needs an API key)',
          ),
        ),
      );
    }
    return SizedBox(
      height: 280,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WbRadius.card),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(items.first.marker.lat, items.first.marker.lng),
            zoom: 11,
          ),
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          markers: {
            for (final p in items)
              Marker(
                markerId: MarkerId(p.entryId),
                position: LatLng(p.marker.lat, p.marker.lng),
                infoWindow: InfoWindow(
                  title: '${p.position}. ${p.marker.name}',
                ),
              ),
          },
        ),
      ),
    );
  }
}
