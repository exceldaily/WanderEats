import 'package:freezed_annotation/freezed_annotation.dart';

part 'recommendation.freezed.dart';
part 'recommendation.g.dart';

@freezed
abstract class Recommendation with _$Recommendation {
  const factory Recommendation({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'restaurant_id') required String restaurantId,
    required String body,
    @JsonKey(name: 'what_to_order') String? whatToOrder,
    @JsonKey(name: 'price_impression') int? priceImpression,
    @JsonKey(name: 'visited_on') String? visitedOn,
    @Default('public') String visibility,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    // Joined author fields (profiles embed)
    @JsonKey(name: 'profiles') Map<String, dynamic>? author,
    // Joined photos
    @JsonKey(name: 'recommendation_photos')
    @Default(<Map<String, dynamic>>[])
    List<Map<String, dynamic>> photos,
  }) = _Recommendation;

  factory Recommendation.fromJson(Map<String, dynamic> json) =>
      _$RecommendationFromJson(json);
}

/// Feedback options, in product language.
enum RecFeedbackRating {
  exact('exact', 'Exactly as described'),
  great('great', 'Great recommendation'),
  somewhat('somewhat', 'Somewhat useful'),
  mismatch('mismatch', 'Did not match');

  const RecFeedbackRating(this.value, this.label);
  final String value;
  final String label;
}
