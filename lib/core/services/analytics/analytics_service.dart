import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Typed analytics facade. Presentation code calls these named methods;
/// nothing in the widget tree ever builds raw event maps.
///
/// The active implementation is a debug logger until a Firebase project is
/// configured (see SETUP.md). Swapping in FirebaseAnalyticsService is a
/// one-line provider override.
abstract class AnalyticsService {
  Future<void> signUpCompleted({required String method});
  Future<void> onboardingCompleted();
  Future<void> mapOpened();
  Future<void> markerSelected({required String restaurantId});
  Future<void> restaurantSaved({required String restaurantId});
  Future<void> restaurantVisited({required String restaurantId});
  Future<void> tasterFollowed({required String tasterId});
  Future<void> recommendationCreated({required String restaurantId});
  Future<void> recommendationFeedbackSubmitted({
    required String recommendationId,
  });
  Future<void> listCreated({required String listId});
  Future<void> listFollowed({required String listId});
  Future<void> searchPerformed({
    required String query,
    required int resultCount,
  });
  Future<void> directionsOpened({required String restaurantId});
  Future<void> shareInitiated({
    required String contentType,
    required String id,
  });
  Future<void> subscriptionScreenViewed();
}

/// Development fallback: logs events in debug builds, silent in release.
class DebugAnalyticsService implements AnalyticsService {
  Future<void> _log(
    String event, [
    Map<String, Object?> params = const {},
  ]) async {
    if (kDebugMode) {
      debugPrint('[analytics] $event ${params.isEmpty ? '' : params}');
    }
  }

  @override
  Future<void> signUpCompleted({required String method}) =>
      _log('sign_up_completed', {'method': method});
  @override
  Future<void> onboardingCompleted() => _log('onboarding_completed');
  @override
  Future<void> mapOpened() => _log('map_opened');
  @override
  Future<void> markerSelected({required String restaurantId}) =>
      _log('marker_selected', {'restaurant_id': restaurantId});
  @override
  Future<void> restaurantSaved({required String restaurantId}) =>
      _log('restaurant_saved', {'restaurant_id': restaurantId});
  @override
  Future<void> restaurantVisited({required String restaurantId}) =>
      _log('restaurant_visited', {'restaurant_id': restaurantId});
  @override
  Future<void> tasterFollowed({required String tasterId}) =>
      _log('taster_followed', {'taster_id': tasterId});
  @override
  Future<void> recommendationCreated({required String restaurantId}) =>
      _log('recommendation_created', {'restaurant_id': restaurantId});
  @override
  Future<void> recommendationFeedbackSubmitted({
    required String recommendationId,
  }) => _log('recommendation_feedback_submitted', {
    'recommendation_id': recommendationId,
  });
  @override
  Future<void> listCreated({required String listId}) =>
      _log('list_created', {'list_id': listId});
  @override
  Future<void> listFollowed({required String listId}) =>
      _log('list_followed', {'list_id': listId});
  @override
  Future<void> searchPerformed({
    required String query,
    required int resultCount,
  }) => _log('search_performed', {'query': query, 'result_count': resultCount});
  @override
  Future<void> directionsOpened({required String restaurantId}) =>
      _log('directions_opened', {'restaurant_id': restaurantId});
  @override
  Future<void> shareInitiated({
    required String contentType,
    required String id,
  }) => _log('share_initiated', {'content_type': contentType, 'id': id});
  @override
  Future<void> subscriptionScreenViewed() => _log('subscription_screen_viewed');
}

final analyticsProvider = Provider<AnalyticsService>((ref) {
  return DebugAnalyticsService();
});
