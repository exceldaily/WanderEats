// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'food_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FoodList {

 String get id;@JsonKey(name: 'owner_id') String get ownerId; String get title; String? get description;@JsonKey(name: 'cover_url') String? get coverUrl; String get visibility;@JsonKey(name: 'is_collaborative') bool get isCollaborative;@JsonKey(name: 'created_at') DateTime get createdAt;// Joined owner (profiles embed)
@JsonKey(name: 'profiles') Map<String, dynamic>? get owner;
/// Create a copy of FoodList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodListCopyWith<FoodList> get copyWith => _$FoodListCopyWithImpl<FoodList>(this as FoodList, _$identity);

  /// Serializes this FoodList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodList&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.isCollaborative, isCollaborative) || other.isCollaborative == isCollaborative)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.owner, owner));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ownerId,title,description,coverUrl,visibility,isCollaborative,createdAt,const DeepCollectionEquality().hash(owner));

@override
String toString() {
  return 'FoodList(id: $id, ownerId: $ownerId, title: $title, description: $description, coverUrl: $coverUrl, visibility: $visibility, isCollaborative: $isCollaborative, createdAt: $createdAt, owner: $owner)';
}


}

/// @nodoc
abstract mixin class $FoodListCopyWith<$Res>  {
  factory $FoodListCopyWith(FoodList value, $Res Function(FoodList) _then) = _$FoodListCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'owner_id') String ownerId, String title, String? description,@JsonKey(name: 'cover_url') String? coverUrl, String visibility,@JsonKey(name: 'is_collaborative') bool isCollaborative,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'profiles') Map<String, dynamic>? owner
});




}
/// @nodoc
class _$FoodListCopyWithImpl<$Res>
    implements $FoodListCopyWith<$Res> {
  _$FoodListCopyWithImpl(this._self, this._then);

  final FoodList _self;
  final $Res Function(FoodList) _then;

/// Create a copy of FoodList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerId = null,Object? title = null,Object? description = freezed,Object? coverUrl = freezed,Object? visibility = null,Object? isCollaborative = null,Object? createdAt = null,Object? owner = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,isCollaborative: null == isCollaborative ? _self.isCollaborative : isCollaborative // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [FoodList].
extension FoodListPatterns on FoodList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FoodList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FoodList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FoodList value)  $default,){
final _that = this;
switch (_that) {
case _FoodList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FoodList value)?  $default,){
final _that = this;
switch (_that) {
case _FoodList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'owner_id')  String ownerId,  String title,  String? description, @JsonKey(name: 'cover_url')  String? coverUrl,  String visibility, @JsonKey(name: 'is_collaborative')  bool isCollaborative, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'profiles')  Map<String, dynamic>? owner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FoodList() when $default != null:
return $default(_that.id,_that.ownerId,_that.title,_that.description,_that.coverUrl,_that.visibility,_that.isCollaborative,_that.createdAt,_that.owner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'owner_id')  String ownerId,  String title,  String? description, @JsonKey(name: 'cover_url')  String? coverUrl,  String visibility, @JsonKey(name: 'is_collaborative')  bool isCollaborative, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'profiles')  Map<String, dynamic>? owner)  $default,) {final _that = this;
switch (_that) {
case _FoodList():
return $default(_that.id,_that.ownerId,_that.title,_that.description,_that.coverUrl,_that.visibility,_that.isCollaborative,_that.createdAt,_that.owner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'owner_id')  String ownerId,  String title,  String? description, @JsonKey(name: 'cover_url')  String? coverUrl,  String visibility, @JsonKey(name: 'is_collaborative')  bool isCollaborative, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'profiles')  Map<String, dynamic>? owner)?  $default,) {final _that = this;
switch (_that) {
case _FoodList() when $default != null:
return $default(_that.id,_that.ownerId,_that.title,_that.description,_that.coverUrl,_that.visibility,_that.isCollaborative,_that.createdAt,_that.owner);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FoodList implements FoodList {
  const _FoodList({required this.id, @JsonKey(name: 'owner_id') required this.ownerId, required this.title, this.description, @JsonKey(name: 'cover_url') this.coverUrl, this.visibility = 'public', @JsonKey(name: 'is_collaborative') this.isCollaborative = false, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'profiles') final  Map<String, dynamic>? owner}): _owner = owner;
  factory _FoodList.fromJson(Map<String, dynamic> json) => _$FoodListFromJson(json);

@override final  String id;
@override@JsonKey(name: 'owner_id') final  String ownerId;
@override final  String title;
@override final  String? description;
@override@JsonKey(name: 'cover_url') final  String? coverUrl;
@override@JsonKey() final  String visibility;
@override@JsonKey(name: 'is_collaborative') final  bool isCollaborative;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
// Joined owner (profiles embed)
 final  Map<String, dynamic>? _owner;
// Joined owner (profiles embed)
@override@JsonKey(name: 'profiles') Map<String, dynamic>? get owner {
  final value = _owner;
  if (value == null) return null;
  if (_owner is EqualUnmodifiableMapView) return _owner;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of FoodList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoodListCopyWith<_FoodList> get copyWith => __$FoodListCopyWithImpl<_FoodList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FoodListToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FoodList&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.isCollaborative, isCollaborative) || other.isCollaborative == isCollaborative)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._owner, _owner));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ownerId,title,description,coverUrl,visibility,isCollaborative,createdAt,const DeepCollectionEquality().hash(_owner));

@override
String toString() {
  return 'FoodList(id: $id, ownerId: $ownerId, title: $title, description: $description, coverUrl: $coverUrl, visibility: $visibility, isCollaborative: $isCollaborative, createdAt: $createdAt, owner: $owner)';
}


}

/// @nodoc
abstract mixin class _$FoodListCopyWith<$Res> implements $FoodListCopyWith<$Res> {
  factory _$FoodListCopyWith(_FoodList value, $Res Function(_FoodList) _then) = __$FoodListCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'owner_id') String ownerId, String title, String? description,@JsonKey(name: 'cover_url') String? coverUrl, String visibility,@JsonKey(name: 'is_collaborative') bool isCollaborative,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'profiles') Map<String, dynamic>? owner
});




}
/// @nodoc
class __$FoodListCopyWithImpl<$Res>
    implements _$FoodListCopyWith<$Res> {
  __$FoodListCopyWithImpl(this._self, this._then);

  final _FoodList _self;
  final $Res Function(_FoodList) _then;

/// Create a copy of FoodList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerId = null,Object? title = null,Object? description = freezed,Object? coverUrl = freezed,Object? visibility = null,Object? isCollaborative = null,Object? createdAt = null,Object? owner = freezed,}) {
  return _then(_FoodList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,isCollaborative: null == isCollaborative ? _self.isCollaborative : isCollaborative // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,owner: freezed == owner ? _self._owner : owner // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
