import 'package:freezed_annotation/freezed_annotation.dart';

import '../../restaurants/domain/restaurant.dart';

part 'food_list.freezed.dart';
part 'food_list.g.dart';

@freezed
abstract class FoodList with _$FoodList {
  const factory FoodList({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    required String title,
    String? description,
    @JsonKey(name: 'cover_url') String? coverUrl,
    @Default('public') String visibility,
    @JsonKey(name: 'is_collaborative') @Default(false) bool isCollaborative,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    // Joined owner (profiles embed)
    @JsonKey(name: 'profiles') Map<String, dynamic>? owner,
  }) = _FoodList;

  factory FoodList.fromJson(Map<String, dynamic> json) =>
      _$FoodListFromJson(json);
}

/// One ordered restaurant inside a list, with coordinates for the map view.
class ListPlace {
  const ListPlace({
    required this.entryId,
    required this.position,
    this.note,
    required this.marker,
  });

  final String entryId;
  final int position;
  final String? note;
  final RestaurantMarker marker;

  factory ListPlace.fromJson(Map<String, dynamic> json) => ListPlace(
    entryId: json['entry_id'] as String,
    position: (json['sort_position'] as num?)?.toInt() ?? 0,
    note: json['note'] as String?,
    marker: RestaurantMarker.fromJson(json),
  );
}
