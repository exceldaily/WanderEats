import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/analytics/analytics_service.dart';
import '../../restaurants/presentation/restaurant_actions.dart';
import '../data/biteswipe_repository.dart';
import '../domain/swipe_card.dart';

class BiteSwipeFilters {
  const BiteSwipeFilters({this.maxPrice, this.radiusM = 3000, this.cuisineId});

  final int? maxPrice;
  final int radiusM;
  final String? cuisineId;

  BiteSwipeFilters copyWith({
    int? Function()? maxPrice,
    int? radiusM,
    String? Function()? cuisineId,
  }) => BiteSwipeFilters(
    maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
    radiusM: radiusM ?? this.radiusM,
    cuisineId: cuisineId != null ? cuisineId() : this.cuisineId,
  );

  bool get isActive => maxPrice != null || cuisineId != null || radiusM != 3000;

  Map<String, dynamic> toJson() => {
    'max_price': maxPrice,
    'radius_m': radiusM,
    'cuisine_id': cuisineId,
  };
}

/// A swipe we can still take back.
class _LastAction {
  const _LastAction(this.card, this.index, this.wasSave);
  final SwipeCard card;
  final int index;
  final bool wasSave;
}

class BiteSwipeState {
  const BiteSwipeState({
    this.cards = const [],
    this.index = 0,
    this.loading = true,
    this.error,
    this.filters = const BiteSwipeFilters(),
    this.savedIds = const {},
    this.tasterIds = const {},
    this.skippedCount = 0,
    this.canUndo = false,
    this.locationLabel,
  });

  final List<SwipeCard> cards;
  final int index;
  final bool loading;
  final String? error;
  final BiteSwipeFilters filters;

  /// Saved during this session, for the completion summary.
  final Set<String> savedIds;
  final Set<String> tasterIds;
  final int skippedCount;
  final bool canUndo;
  final String? locationLabel;

  SwipeCard? get current => index < cards.length ? cards[index] : null;
  SwipeCard? get next => index + 1 < cards.length ? cards[index + 1] : null;
  bool get finished => !loading && error == null && index >= cards.length;
  int get remaining => (cards.length - index).clamp(0, cards.length);

  BiteSwipeState copyWith({
    List<SwipeCard>? cards,
    int? index,
    bool? loading,
    String? Function()? error,
    BiteSwipeFilters? filters,
    Set<String>? savedIds,
    Set<String>? tasterIds,
    int? skippedCount,
    bool? canUndo,
    String? locationLabel,
  }) => BiteSwipeState(
    cards: cards ?? this.cards,
    index: index ?? this.index,
    loading: loading ?? this.loading,
    error: error != null ? error() : this.error,
    filters: filters ?? this.filters,
    savedIds: savedIds ?? this.savedIds,
    tasterIds: tasterIds ?? this.tasterIds,
    skippedCount: skippedCount ?? this.skippedCount,
    canUndo: canUndo ?? this.canUndo,
    locationLabel: locationLabel ?? this.locationLabel,
  );
}

/// Drives one BiteSwipe run. All ordering comes from the server; this only
/// advances through it and records what the user did.
class BiteSwipeController extends Notifier<BiteSwipeState> {
  double? _lat;
  double? _lng;
  String? _sessionId;
  _LastAction? _last;

  @override
  BiteSwipeState build() => const BiteSwipeState();

  Future<void> load({
    required double lat,
    required double lng,
    String? locationLabel,
  }) async {
    _lat = lat;
    _lng = lng;
    state = state.copyWith(
      loading: true,
      error: () => null,
      locationLabel: locationLabel,
    );
    await _fetch();
  }

  Future<void> _fetch() async {
    final lat = _lat, lng = _lng;
    if (lat == null || lng == null) return;
    try {
      final repo = ref.read(biteSwipeRepositoryProvider);
      final cards = await repo.deck(
        lat: lat,
        lng: lng,
        radiusM: state.filters.radiusM,
        maxPrice: state.filters.maxPrice,
        cuisineId: state.filters.cuisineId,
      );
      _sessionId ??= await repo.startSession(
        lat: lat,
        lng: lng,
        radiusM: state.filters.radiusM,
        filters: state.filters.toJson(),
      );
      state = state.copyWith(
        cards: cards,
        index: 0,
        loading: false,
        error: () => null,
        canUndo: false,
      );
      _recordShown();
    } catch (e) {
      state = state.copyWith(loading: false, error: () => e.toString());
    }
  }

  void _recordShown() {
    final card = state.current;
    final session = _sessionId;
    if (card == null || session == null) return;
    unawaited(
      ref
          .read(biteSwipeRepositoryProvider)
          .recordImpression(
            sessionId: session,
            card: card,
            position: state.index,
            action: 'shown',
          ),
    );
  }

  Future<void> save() async {
    final card = state.current;
    if (card == null) return;
    final repo = ref.read(biteSwipeRepositoryProvider);
    final session = _sessionId;

    // Optimistic: the card leaves immediately, persistence follows.
    _last = _LastAction(card, state.index, true);
    state = state.copyWith(
      index: state.index + 1,
      savedIds: {...state.savedIds, card.id},
      tasterIds: {
        ...state.tasterIds,
        if (card.viaTasterId != null) card.viaTasterId!,
      },
      canUndo: true,
    );

    await ref.read(savedIdsProvider.notifier).toggle(card.id);
    unawaited(
      ref.read(analyticsProvider).restaurantSaved(restaurantId: card.id),
    );
    if (session != null) {
      unawaited(
        repo.recordSaveSource(
          restaurantId: card.id,
          sessionId: session,
          viaTasterId: card.viaTasterId,
        ),
      );
      unawaited(
        repo.recordImpression(
          sessionId: session,
          card: card,
          position: _last!.index,
          action: 'saved',
        ),
      );
    }
    _recordShown();
  }

  Future<void> skip() async {
    final card = state.current;
    if (card == null) return;
    final repo = ref.read(biteSwipeRepositoryProvider);
    final session = _sessionId;

    _last = _LastAction(card, state.index, false);
    state = state.copyWith(
      index: state.index + 1,
      skippedCount: state.skippedCount + 1,
      canUndo: true,
    );

    unawaited(repo.skip(card.id));
    if (session != null) {
      unawaited(
        repo.recordImpression(
          sessionId: session,
          card: card,
          position: _last!.index,
          action: 'skipped',
        ),
      );
    }
    _recordShown();
  }

  /// Restores the previous card and reverses whatever it recorded.
  Future<void> undo() async {
    final last = _last;
    if (last == null) return;
    final repo = ref.read(biteSwipeRepositoryProvider);
    _last = null;

    final saved = {...state.savedIds}..remove(last.card.id);
    state = state.copyWith(
      index: last.index,
      savedIds: saved,
      skippedCount: last.wasSave
          ? state.skippedCount
          : (state.skippedCount - 1).clamp(0, 1 << 30),
      canUndo: false,
    );

    if (last.wasSave) {
      await ref.read(savedIdsProvider.notifier).toggle(last.card.id);
    } else {
      unawaited(repo.unskip(last.card.id));
    }
    final session = _sessionId;
    if (session != null) {
      unawaited(
        repo.recordImpression(
          sessionId: session,
          card: last.card,
          position: last.index,
          action: 'undone',
        ),
      );
    }
  }

  Future<void> recordSkipReason(SkipReason reason) async {
    final last = _last;
    if (last == null) return;
    await ref
        .read(biteSwipeRepositoryProvider)
        .recordSkipReason(restaurantId: last.card.id, reason: reason);
  }

  Future<void> setFilters(BiteSwipeFilters filters) async {
    state = state.copyWith(filters: filters, loading: true);
    await _fetch();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    await _fetch();
  }

  /// Called when the deck is exhausted or the user leaves.
  Future<void> finish() async {
    final session = _sessionId;
    if (session == null) return;
    _sessionId = null;
    await ref
        .read(biteSwipeRepositoryProvider)
        .endSession(
          session,
          saved: state.savedIds.length,
          skipped: state.skippedCount,
          tasters: state.tasterIds.length,
        );
  }
}

final biteSwipeControllerProvider =
    NotifierProvider<BiteSwipeController, BiteSwipeState>(
      BiteSwipeController.new,
    );
