import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/networking/supabase_provider.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../domain/action_context.dart';

/// Builds the row written to restaurant_conversion_events.
///
/// Pure and separate from the network call so the attribution shape can be
/// tested without a database. Keys match the column names exactly; anything
/// null is omitted rather than sent, so the column defaults apply.
Map<String, dynamic> buildConversionRow({
  required String restaurantId,
  required RestaurantAction action,
  required ActionContext context,
  String? userId,
  String? anonymousSessionId,
  String? sessionId,
  String? provider,
  String? destination,
  String? appVersion,
  String? platform,
  Map<String, dynamic> metadata = const {},
}) {
  return {
    'restaurant_id': restaurantId,
    'action_type': action.wire,
    'source_screen': context.source.wire,
    if (context.sourceFeature != null) 'source_feature': context.sourceFeature,
    'user_id': ?userId,
    'anonymous_session_id': ?anonymousSessionId,
    if (context.tasterId != null) 'taster_id': context.tasterId,
    if (context.recommendationId != null)
      'recommendation_id': context.recommendationId,
    if (context.listId != null) 'list_id': context.listId,
    if (context.cityId != null) 'city_id': context.cityId,
    'provider': ?provider,
    'destination': ?destination,
    'session_id': ?sessionId,
    'app_version': ?appVersion,
    'platform': ?platform,
    if (metadata.isNotEmpty) 'metadata': metadata,
  };
}

/// Records outbound restaurant actions for attribution and business reporting.
///
/// Deliberately separate from AnalyticsService: that one feeds Firebase, which
/// cannot be joined against restaurants or tasters. A business dashboard has to
/// query these rows, so they live in Postgres.
class ConversionRepository {
  ConversionRepository(this._schema);

  final SupabaseQuerySchema _schema;

  /// Records an action. Never throws.
  ///
  /// Tracking is not worth breaking a user's tap over: if the insert fails the
  /// user still gets their directions. Returns whether it was recorded, so
  /// tests and callers can assert when they care.
  Future<bool> record({
    required String restaurantId,
    required RestaurantAction action,
    required ActionContext context,
    String? userId,
    String? anonymousSessionId,
    String? sessionId,
    String? provider,
    String? destination,
    String? appVersion,
    String? platform,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      await _schema.from('restaurant_conversion_events').insert(
            buildConversionRow(
              restaurantId: restaurantId,
              action: action,
              context: context,
              userId: userId,
              anonymousSessionId: anonymousSessionId,
              sessionId: sessionId,
              provider: provider,
              destination: destination,
              appVersion: appVersion,
              platform: platform,
              metadata: metadata,
            ),
          );
      return true;
    } on PostgrestException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

final conversionRepositoryProvider = Provider<ConversionRepository>((ref) {
  return ConversionRepository(ref.watch(wbSchemaProvider));
});

/// Records an action for the signed-in user, filling in the user id.
///
/// A single entry point so presentation code never assembles an event map, and
/// never has to remember to attach the current user.
final trackRestaurantActionProvider = Provider<TrackRestaurantAction>((ref) {
  return TrackRestaurantAction(ref);
});

class TrackRestaurantAction {
  TrackRestaurantAction(this._ref);

  final Ref _ref;

  Future<void> call({
    required String restaurantId,
    required RestaurantAction action,
    required ActionContext context,
    String? provider,
    String? destination,
    Map<String, dynamic> metadata = const {},
  }) async {
    final userId = _ref.read(sessionProvider)?.user.id;
    await _ref
        .read(conversionRepositoryProvider)
        .record(
          restaurantId: restaurantId,
          action: action,
          context: context,
          userId: userId,
          provider: provider,
          destination: destination,
          metadata: metadata,
        );
  }
}
