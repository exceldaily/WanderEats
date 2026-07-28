// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FoodList _$FoodListFromJson(Map<String, dynamic> json) => _FoodList(
  id: json['id'] as String,
  ownerId: json['owner_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  coverUrl: json['cover_url'] as String?,
  visibility: json['visibility'] as String? ?? 'public',
  isCollaborative: json['is_collaborative'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
  owner: json['profiles'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$FoodListToJson(_FoodList instance) => <String, dynamic>{
  'id': instance.id,
  'owner_id': instance.ownerId,
  'title': instance.title,
  'description': instance.description,
  'cover_url': instance.coverUrl,
  'visibility': instance.visibility,
  'is_collaborative': instance.isCollaborative,
  'created_at': instance.createdAt.toIso8601String(),
  'profiles': instance.owner,
};
