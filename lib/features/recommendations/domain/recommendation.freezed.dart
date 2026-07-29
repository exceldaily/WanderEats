// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recommendation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Recommendation {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'restaurant_id') String get restaurantId; String get body;@JsonKey(name: 'what_to_order') String? get whatToOrder;@JsonKey(name: 'price_impression') int? get priceImpression;@JsonKey(name: 'visited_on') String? get visitedOn; String get visibility;@JsonKey(name: 'created_at') DateTime get createdAt;// Joined author fields (profiles embed)
@JsonKey(name: 'profiles') Map<String, dynamic>? get author;// Joined restaurant fields (restaurants embed): name, cover_photo_url,
// price_level, cities(name, countries(name)). The card leads with these.
@JsonKey(name: 'restaurants') Map<String, dynamic>? get restaurant;// Joined photos
@JsonKey(name: 'recommendation_photos') List<Map<String, dynamic>> get photos;
/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecommendationCopyWith<Recommendation> get copyWith => _$RecommendationCopyWithImpl<Recommendation>(this as Recommendation, _$identity);

  /// Serializes this Recommendation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recommendation&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.restaurantId, restaurantId) || other.restaurantId == restaurantId)&&(identical(other.body, body) || other.body == body)&&(identical(other.whatToOrder, whatToOrder) || other.whatToOrder == whatToOrder)&&(identical(other.priceImpression, priceImpression) || other.priceImpression == priceImpression)&&(identical(other.visitedOn, visitedOn) || other.visitedOn == visitedOn)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.author, author)&&const DeepCollectionEquality().equals(other.restaurant, restaurant)&&const DeepCollectionEquality().equals(other.photos, photos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,restaurantId,body,whatToOrder,priceImpression,visitedOn,visibility,createdAt,const DeepCollectionEquality().hash(author),const DeepCollectionEquality().hash(restaurant),const DeepCollectionEquality().hash(photos));

@override
String toString() {
  return 'Recommendation(id: $id, userId: $userId, restaurantId: $restaurantId, body: $body, whatToOrder: $whatToOrder, priceImpression: $priceImpression, visitedOn: $visitedOn, visibility: $visibility, createdAt: $createdAt, author: $author, restaurant: $restaurant, photos: $photos)';
}


}

/// @nodoc
abstract mixin class $RecommendationCopyWith<$Res>  {
  factory $RecommendationCopyWith(Recommendation value, $Res Function(Recommendation) _then) = _$RecommendationCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'restaurant_id') String restaurantId, String body,@JsonKey(name: 'what_to_order') String? whatToOrder,@JsonKey(name: 'price_impression') int? priceImpression,@JsonKey(name: 'visited_on') String? visitedOn, String visibility,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'profiles') Map<String, dynamic>? author,@JsonKey(name: 'restaurants') Map<String, dynamic>? restaurant,@JsonKey(name: 'recommendation_photos') List<Map<String, dynamic>> photos
});




}
/// @nodoc
class _$RecommendationCopyWithImpl<$Res>
    implements $RecommendationCopyWith<$Res> {
  _$RecommendationCopyWithImpl(this._self, this._then);

  final Recommendation _self;
  final $Res Function(Recommendation) _then;

/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? restaurantId = null,Object? body = null,Object? whatToOrder = freezed,Object? priceImpression = freezed,Object? visitedOn = freezed,Object? visibility = null,Object? createdAt = null,Object? author = freezed,Object? restaurant = freezed,Object? photos = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,restaurantId: null == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,whatToOrder: freezed == whatToOrder ? _self.whatToOrder : whatToOrder // ignore: cast_nullable_to_non_nullable
as String?,priceImpression: freezed == priceImpression ? _self.priceImpression : priceImpression // ignore: cast_nullable_to_non_nullable
as int?,visitedOn: freezed == visitedOn ? _self.visitedOn : visitedOn // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,restaurant: freezed == restaurant ? _self.restaurant : restaurant // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}

}


/// Adds pattern-matching-related methods to [Recommendation].
extension RecommendationPatterns on Recommendation {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recommendation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recommendation value)  $default,){
final _that = this;
switch (_that) {
case _Recommendation():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recommendation value)?  $default,){
final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'restaurant_id')  String restaurantId,  String body, @JsonKey(name: 'what_to_order')  String? whatToOrder, @JsonKey(name: 'price_impression')  int? priceImpression, @JsonKey(name: 'visited_on')  String? visitedOn,  String visibility, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'profiles')  Map<String, dynamic>? author, @JsonKey(name: 'restaurants')  Map<String, dynamic>? restaurant, @JsonKey(name: 'recommendation_photos')  List<Map<String, dynamic>> photos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
return $default(_that.id,_that.userId,_that.restaurantId,_that.body,_that.whatToOrder,_that.priceImpression,_that.visitedOn,_that.visibility,_that.createdAt,_that.author,_that.restaurant,_that.photos);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'restaurant_id')  String restaurantId,  String body, @JsonKey(name: 'what_to_order')  String? whatToOrder, @JsonKey(name: 'price_impression')  int? priceImpression, @JsonKey(name: 'visited_on')  String? visitedOn,  String visibility, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'profiles')  Map<String, dynamic>? author, @JsonKey(name: 'restaurants')  Map<String, dynamic>? restaurant, @JsonKey(name: 'recommendation_photos')  List<Map<String, dynamic>> photos)  $default,) {final _that = this;
switch (_that) {
case _Recommendation():
return $default(_that.id,_that.userId,_that.restaurantId,_that.body,_that.whatToOrder,_that.priceImpression,_that.visitedOn,_that.visibility,_that.createdAt,_that.author,_that.restaurant,_that.photos);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'restaurant_id')  String restaurantId,  String body, @JsonKey(name: 'what_to_order')  String? whatToOrder, @JsonKey(name: 'price_impression')  int? priceImpression, @JsonKey(name: 'visited_on')  String? visitedOn,  String visibility, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'profiles')  Map<String, dynamic>? author, @JsonKey(name: 'restaurants')  Map<String, dynamic>? restaurant, @JsonKey(name: 'recommendation_photos')  List<Map<String, dynamic>> photos)?  $default,) {final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
return $default(_that.id,_that.userId,_that.restaurantId,_that.body,_that.whatToOrder,_that.priceImpression,_that.visitedOn,_that.visibility,_that.createdAt,_that.author,_that.restaurant,_that.photos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Recommendation implements Recommendation {
  const _Recommendation({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'restaurant_id') required this.restaurantId, required this.body, @JsonKey(name: 'what_to_order') this.whatToOrder, @JsonKey(name: 'price_impression') this.priceImpression, @JsonKey(name: 'visited_on') this.visitedOn, this.visibility = 'public', @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'profiles') final  Map<String, dynamic>? author, @JsonKey(name: 'restaurants') final  Map<String, dynamic>? restaurant, @JsonKey(name: 'recommendation_photos') final  List<Map<String, dynamic>> photos = const <Map<String, dynamic>>[]}): _author = author,_restaurant = restaurant,_photos = photos;
  factory _Recommendation.fromJson(Map<String, dynamic> json) => _$RecommendationFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'restaurant_id') final  String restaurantId;
@override final  String body;
@override@JsonKey(name: 'what_to_order') final  String? whatToOrder;
@override@JsonKey(name: 'price_impression') final  int? priceImpression;
@override@JsonKey(name: 'visited_on') final  String? visitedOn;
@override@JsonKey() final  String visibility;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
// Joined author fields (profiles embed)
 final  Map<String, dynamic>? _author;
// Joined author fields (profiles embed)
@override@JsonKey(name: 'profiles') Map<String, dynamic>? get author {
  final value = _author;
  if (value == null) return null;
  if (_author is EqualUnmodifiableMapView) return _author;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

// Joined restaurant fields (restaurants embed): name, cover_photo_url,
// price_level, cities(name, countries(name)). The card leads with these.
 final  Map<String, dynamic>? _restaurant;
// Joined restaurant fields (restaurants embed): name, cover_photo_url,
// price_level, cities(name, countries(name)). The card leads with these.
@override@JsonKey(name: 'restaurants') Map<String, dynamic>? get restaurant {
  final value = _restaurant;
  if (value == null) return null;
  if (_restaurant is EqualUnmodifiableMapView) return _restaurant;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

// Joined photos
 final  List<Map<String, dynamic>> _photos;
// Joined photos
@override@JsonKey(name: 'recommendation_photos') List<Map<String, dynamic>> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}


/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecommendationCopyWith<_Recommendation> get copyWith => __$RecommendationCopyWithImpl<_Recommendation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecommendationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recommendation&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.restaurantId, restaurantId) || other.restaurantId == restaurantId)&&(identical(other.body, body) || other.body == body)&&(identical(other.whatToOrder, whatToOrder) || other.whatToOrder == whatToOrder)&&(identical(other.priceImpression, priceImpression) || other.priceImpression == priceImpression)&&(identical(other.visitedOn, visitedOn) || other.visitedOn == visitedOn)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._author, _author)&&const DeepCollectionEquality().equals(other._restaurant, _restaurant)&&const DeepCollectionEquality().equals(other._photos, _photos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,restaurantId,body,whatToOrder,priceImpression,visitedOn,visibility,createdAt,const DeepCollectionEquality().hash(_author),const DeepCollectionEquality().hash(_restaurant),const DeepCollectionEquality().hash(_photos));

@override
String toString() {
  return 'Recommendation(id: $id, userId: $userId, restaurantId: $restaurantId, body: $body, whatToOrder: $whatToOrder, priceImpression: $priceImpression, visitedOn: $visitedOn, visibility: $visibility, createdAt: $createdAt, author: $author, restaurant: $restaurant, photos: $photos)';
}


}

/// @nodoc
abstract mixin class _$RecommendationCopyWith<$Res> implements $RecommendationCopyWith<$Res> {
  factory _$RecommendationCopyWith(_Recommendation value, $Res Function(_Recommendation) _then) = __$RecommendationCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'restaurant_id') String restaurantId, String body,@JsonKey(name: 'what_to_order') String? whatToOrder,@JsonKey(name: 'price_impression') int? priceImpression,@JsonKey(name: 'visited_on') String? visitedOn, String visibility,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'profiles') Map<String, dynamic>? author,@JsonKey(name: 'restaurants') Map<String, dynamic>? restaurant,@JsonKey(name: 'recommendation_photos') List<Map<String, dynamic>> photos
});




}
/// @nodoc
class __$RecommendationCopyWithImpl<$Res>
    implements _$RecommendationCopyWith<$Res> {
  __$RecommendationCopyWithImpl(this._self, this._then);

  final _Recommendation _self;
  final $Res Function(_Recommendation) _then;

/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? restaurantId = null,Object? body = null,Object? whatToOrder = freezed,Object? priceImpression = freezed,Object? visitedOn = freezed,Object? visibility = null,Object? createdAt = null,Object? author = freezed,Object? restaurant = freezed,Object? photos = null,}) {
  return _then(_Recommendation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,restaurantId: null == restaurantId ? _self.restaurantId : restaurantId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,whatToOrder: freezed == whatToOrder ? _self.whatToOrder : whatToOrder // ignore: cast_nullable_to_non_nullable
as String?,priceImpression: freezed == priceImpression ? _self.priceImpression : priceImpression // ignore: cast_nullable_to_non_nullable
as int?,visitedOn: freezed == visitedOn ? _self.visitedOn : visitedOn // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,author: freezed == author ? _self._author : author // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,restaurant: freezed == restaurant ? _self._restaurant : restaurant // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

// dart format on
