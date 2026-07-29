import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_service.dart';

/// Real implementation, active once Firebase is configured for the platform
/// (google-services.json present on Android). See analytics_service.dart for
/// the interface and the debug fallback used otherwise.
class FirebaseAnalyticsServiceImpl implements AnalyticsService {
  FirebaseAnalyticsServiceImpl(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> signUpCompleted({required String method}) =>
      _analytics.logSignUp(signUpMethod: method);

  @override
  Future<void> onboardingCompleted() =>
      _analytics.logEvent(name: 'onboarding_completed');

  @override
  Future<void> mapOpened() => _analytics.logEvent(name: 'map_opened');

  @override
  Future<void> markerSelected({required String restaurantId}) =>
      _analytics.logEvent(
        name: 'marker_selected',
        parameters: {'restaurant_id': restaurantId},
      );

  @override
  Future<void> restaurantSaved({required String restaurantId}) =>
      _analytics.logEvent(
        name: 'restaurant_saved',
        parameters: {'restaurant_id': restaurantId},
      );

  @override
  Future<void> restaurantVisited({required String restaurantId}) =>
      _analytics.logEvent(
        name: 'restaurant_visited',
        parameters: {'restaurant_id': restaurantId},
      );

  @override
  Future<void> tasterFollowed({required String tasterId}) => _analytics
      .logEvent(name: 'taster_followed', parameters: {'taster_id': tasterId});

  @override
  Future<void> recommendationCreated({required String restaurantId}) =>
      _analytics.logEvent(
        name: 'recommendation_created',
        parameters: {'restaurant_id': restaurantId},
      );

  @override
  Future<void> recommendationFeedbackSubmitted({
    required String recommendationId,
  }) => _analytics.logEvent(
    name: 'recommendation_feedback_submitted',
    parameters: {'recommendation_id': recommendationId},
  );

  @override
  Future<void> listCreated({required String listId}) => _analytics.logEvent(
    name: 'list_created',
    parameters: {'list_id': listId},
  );

  @override
  Future<void> listFollowed({required String listId}) => _analytics.logEvent(
    name: 'list_followed',
    parameters: {'list_id': listId},
  );

  @override
  Future<void> searchPerformed({
    required String query,
    required int resultCount,
  }) => _analytics.logSearch(searchTerm: query);

  @override
  Future<void> directionsOpened({required String restaurantId}) =>
      _analytics.logEvent(
        name: 'directions_opened',
        parameters: {'restaurant_id': restaurantId},
      );

  @override
  Future<void> shareInitiated({
    required String contentType,
    required String id,
  }) => _analytics.logShare(
    contentType: contentType,
    itemId: id,
    method: 'share_sheet',
  );

  @override
  Future<void> subscriptionScreenViewed() =>
      _analytics.logEvent(name: 'subscription_screen_viewed');

  @override
  Future<void> deckOpened({required String from}) =>
      _analytics.logEvent(name: 'deck_opened', parameters: {'from': from});

  @override
  Future<void> deckCardShown({
    required String restaurantId,
    required String reason,
  }) => _analytics.logEvent(
    name: 'deck_card_shown',
    parameters: {'restaurant_id': restaurantId, 'reason': reason},
  );

  @override
  Future<void> deckSaved({required String restaurantId}) => _analytics.logEvent(
    name: 'deck_saved',
    parameters: {'restaurant_id': restaurantId},
  );

  @override
  Future<void> deckSkipped({required String restaurantId}) =>
      _analytics.logEvent(
        name: 'deck_skipped',
        parameters: {'restaurant_id': restaurantId},
      );

  @override
  Future<void> deckUndo() => _analytics.logEvent(name: 'deck_undo');

  @override
  Future<void> deckTasterPreviewOpened({required String restaurantId}) =>
      _analytics.logEvent(
        name: 'deck_taster_preview_opened',
        parameters: {'restaurant_id': restaurantId},
      );

  @override
  Future<void> deckTasterFollowed({required String tasterId}) =>
      _analytics.logEvent(
        name: 'deck_taster_followed',
        parameters: {'taster_id': tasterId},
      );

  @override
  Future<void> deckFiltersChanged() =>
      _analytics.logEvent(name: 'deck_filters_changed');

  @override
  Future<void> deckCompleted({required int saved, required int tasters}) =>
      _analytics.logEvent(
        name: 'deck_completed',
        parameters: {'saved': saved, 'tasters': tasters},
      );

  @override
  Future<void> deckSavedViewedOnMap({required int count}) => _analytics
      .logEvent(name: 'deck_saved_viewed_on_map', parameters: {'count': count});
}
