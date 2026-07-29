// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Profile {

 String get id; String get username;@JsonKey(name: 'display_name') String get displayName; String? get bio;@JsonKey(name: 'avatar_url') String? get avatarUrl;@JsonKey(name: 'header_url') String? get headerUrl;@JsonKey(name: 'home_city_id') String? get homeCityId;@JsonKey(name: 'is_verified') bool get isVerified;@JsonKey(name: 'is_demo') bool get isDemo;@JsonKey(name: 'is_admin') bool get isAdmin;@JsonKey(name: 'onboarding_completed') bool get onboardingCompleted;@JsonKey(name: 'favorite_cuisines') List<String> get favoriteCuisines;@JsonKey(name: 'taste_tags') List<String> get tasteTags;@JsonKey(name: 'banner_style') String get bannerStyle;@JsonKey(name: 'taste_personality') Map<String, dynamic> get tastePersonality;@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileCopyWith<Profile> get copyWith => _$ProfileCopyWithImpl<Profile>(this as Profile, _$identity);

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Profile&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.headerUrl, headerUrl) || other.headerUrl == headerUrl)&&(identical(other.homeCityId, homeCityId) || other.homeCityId == homeCityId)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isDemo, isDemo) || other.isDemo == isDemo)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted)&&const DeepCollectionEquality().equals(other.favoriteCuisines, favoriteCuisines)&&const DeepCollectionEquality().equals(other.tasteTags, tasteTags)&&(identical(other.bannerStyle, bannerStyle) || other.bannerStyle == bannerStyle)&&const DeepCollectionEquality().equals(other.tastePersonality, tastePersonality)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,bio,avatarUrl,headerUrl,homeCityId,isVerified,isDemo,isAdmin,onboardingCompleted,const DeepCollectionEquality().hash(favoriteCuisines),const DeepCollectionEquality().hash(tasteTags),bannerStyle,const DeepCollectionEquality().hash(tastePersonality),createdAt);

@override
String toString() {
  return 'Profile(id: $id, username: $username, displayName: $displayName, bio: $bio, avatarUrl: $avatarUrl, headerUrl: $headerUrl, homeCityId: $homeCityId, isVerified: $isVerified, isDemo: $isDemo, isAdmin: $isAdmin, onboardingCompleted: $onboardingCompleted, favoriteCuisines: $favoriteCuisines, tasteTags: $tasteTags, bannerStyle: $bannerStyle, tastePersonality: $tastePersonality, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ProfileCopyWith<$Res>  {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) _then) = _$ProfileCopyWithImpl;
@useResult
$Res call({
 String id, String username,@JsonKey(name: 'display_name') String displayName, String? bio,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'header_url') String? headerUrl,@JsonKey(name: 'home_city_id') String? homeCityId,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'is_demo') bool isDemo,@JsonKey(name: 'is_admin') bool isAdmin,@JsonKey(name: 'onboarding_completed') bool onboardingCompleted,@JsonKey(name: 'favorite_cuisines') List<String> favoriteCuisines,@JsonKey(name: 'taste_tags') List<String> tasteTags,@JsonKey(name: 'banner_style') String bannerStyle,@JsonKey(name: 'taste_personality') Map<String, dynamic> tastePersonality,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$ProfileCopyWithImpl<$Res>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._self, this._then);

  final Profile _self;
  final $Res Function(Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = null,Object? displayName = null,Object? bio = freezed,Object? avatarUrl = freezed,Object? headerUrl = freezed,Object? homeCityId = freezed,Object? isVerified = null,Object? isDemo = null,Object? isAdmin = null,Object? onboardingCompleted = null,Object? favoriteCuisines = null,Object? tasteTags = null,Object? bannerStyle = null,Object? tastePersonality = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,headerUrl: freezed == headerUrl ? _self.headerUrl : headerUrl // ignore: cast_nullable_to_non_nullable
as String?,homeCityId: freezed == homeCityId ? _self.homeCityId : homeCityId // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isDemo: null == isDemo ? _self.isDemo : isDemo // ignore: cast_nullable_to_non_nullable
as bool,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,favoriteCuisines: null == favoriteCuisines ? _self.favoriteCuisines : favoriteCuisines // ignore: cast_nullable_to_non_nullable
as List<String>,tasteTags: null == tasteTags ? _self.tasteTags : tasteTags // ignore: cast_nullable_to_non_nullable
as List<String>,bannerStyle: null == bannerStyle ? _self.bannerStyle : bannerStyle // ignore: cast_nullable_to_non_nullable
as String,tastePersonality: null == tastePersonality ? _self.tastePersonality : tastePersonality // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Profile].
extension ProfilePatterns on Profile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Profile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Profile value)  $default,){
final _that = this;
switch (_that) {
case _Profile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Profile value)?  $default,){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String username, @JsonKey(name: 'display_name')  String displayName,  String? bio, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'header_url')  String? headerUrl, @JsonKey(name: 'home_city_id')  String? homeCityId, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'is_demo')  bool isDemo, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'onboarding_completed')  bool onboardingCompleted, @JsonKey(name: 'favorite_cuisines')  List<String> favoriteCuisines, @JsonKey(name: 'taste_tags')  List<String> tasteTags, @JsonKey(name: 'banner_style')  String bannerStyle, @JsonKey(name: 'taste_personality')  Map<String, dynamic> tastePersonality, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.username,_that.displayName,_that.bio,_that.avatarUrl,_that.headerUrl,_that.homeCityId,_that.isVerified,_that.isDemo,_that.isAdmin,_that.onboardingCompleted,_that.favoriteCuisines,_that.tasteTags,_that.bannerStyle,_that.tastePersonality,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String username, @JsonKey(name: 'display_name')  String displayName,  String? bio, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'header_url')  String? headerUrl, @JsonKey(name: 'home_city_id')  String? homeCityId, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'is_demo')  bool isDemo, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'onboarding_completed')  bool onboardingCompleted, @JsonKey(name: 'favorite_cuisines')  List<String> favoriteCuisines, @JsonKey(name: 'taste_tags')  List<String> tasteTags, @JsonKey(name: 'banner_style')  String bannerStyle, @JsonKey(name: 'taste_personality')  Map<String, dynamic> tastePersonality, @JsonKey(name: 'created_at')  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Profile():
return $default(_that.id,_that.username,_that.displayName,_that.bio,_that.avatarUrl,_that.headerUrl,_that.homeCityId,_that.isVerified,_that.isDemo,_that.isAdmin,_that.onboardingCompleted,_that.favoriteCuisines,_that.tasteTags,_that.bannerStyle,_that.tastePersonality,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String username, @JsonKey(name: 'display_name')  String displayName,  String? bio, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'header_url')  String? headerUrl, @JsonKey(name: 'home_city_id')  String? homeCityId, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'is_demo')  bool isDemo, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'onboarding_completed')  bool onboardingCompleted, @JsonKey(name: 'favorite_cuisines')  List<String> favoriteCuisines, @JsonKey(name: 'taste_tags')  List<String> tasteTags, @JsonKey(name: 'banner_style')  String bannerStyle, @JsonKey(name: 'taste_personality')  Map<String, dynamic> tastePersonality, @JsonKey(name: 'created_at')  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.username,_that.displayName,_that.bio,_that.avatarUrl,_that.headerUrl,_that.homeCityId,_that.isVerified,_that.isDemo,_that.isAdmin,_that.onboardingCompleted,_that.favoriteCuisines,_that.tasteTags,_that.bannerStyle,_that.tastePersonality,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Profile implements Profile {
  const _Profile({required this.id, required this.username, @JsonKey(name: 'display_name') required this.displayName, this.bio, @JsonKey(name: 'avatar_url') this.avatarUrl, @JsonKey(name: 'header_url') this.headerUrl, @JsonKey(name: 'home_city_id') this.homeCityId, @JsonKey(name: 'is_verified') this.isVerified = false, @JsonKey(name: 'is_demo') this.isDemo = false, @JsonKey(name: 'is_admin') this.isAdmin = false, @JsonKey(name: 'onboarding_completed') this.onboardingCompleted = false, @JsonKey(name: 'favorite_cuisines') final  List<String> favoriteCuisines = const <String>[], @JsonKey(name: 'taste_tags') final  List<String> tasteTags = const <String>[], @JsonKey(name: 'banner_style') this.bannerStyle = 'voyage', @JsonKey(name: 'taste_personality') final  Map<String, dynamic> tastePersonality = const <String, dynamic>{}, @JsonKey(name: 'created_at') required this.createdAt}): _favoriteCuisines = favoriteCuisines,_tasteTags = tasteTags,_tastePersonality = tastePersonality;
  factory _Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

@override final  String id;
@override final  String username;
@override@JsonKey(name: 'display_name') final  String displayName;
@override final  String? bio;
@override@JsonKey(name: 'avatar_url') final  String? avatarUrl;
@override@JsonKey(name: 'header_url') final  String? headerUrl;
@override@JsonKey(name: 'home_city_id') final  String? homeCityId;
@override@JsonKey(name: 'is_verified') final  bool isVerified;
@override@JsonKey(name: 'is_demo') final  bool isDemo;
@override@JsonKey(name: 'is_admin') final  bool isAdmin;
@override@JsonKey(name: 'onboarding_completed') final  bool onboardingCompleted;
 final  List<String> _favoriteCuisines;
@override@JsonKey(name: 'favorite_cuisines') List<String> get favoriteCuisines {
  if (_favoriteCuisines is EqualUnmodifiableListView) return _favoriteCuisines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_favoriteCuisines);
}

 final  List<String> _tasteTags;
@override@JsonKey(name: 'taste_tags') List<String> get tasteTags {
  if (_tasteTags is EqualUnmodifiableListView) return _tasteTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasteTags);
}

@override@JsonKey(name: 'banner_style') final  String bannerStyle;
 final  Map<String, dynamic> _tastePersonality;
@override@JsonKey(name: 'taste_personality') Map<String, dynamic> get tastePersonality {
  if (_tastePersonality is EqualUnmodifiableMapView) return _tastePersonality;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_tastePersonality);
}

@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileCopyWith<_Profile> get copyWith => __$ProfileCopyWithImpl<_Profile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Profile&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.headerUrl, headerUrl) || other.headerUrl == headerUrl)&&(identical(other.homeCityId, homeCityId) || other.homeCityId == homeCityId)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isDemo, isDemo) || other.isDemo == isDemo)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted)&&const DeepCollectionEquality().equals(other._favoriteCuisines, _favoriteCuisines)&&const DeepCollectionEquality().equals(other._tasteTags, _tasteTags)&&(identical(other.bannerStyle, bannerStyle) || other.bannerStyle == bannerStyle)&&const DeepCollectionEquality().equals(other._tastePersonality, _tastePersonality)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,displayName,bio,avatarUrl,headerUrl,homeCityId,isVerified,isDemo,isAdmin,onboardingCompleted,const DeepCollectionEquality().hash(_favoriteCuisines),const DeepCollectionEquality().hash(_tasteTags),bannerStyle,const DeepCollectionEquality().hash(_tastePersonality),createdAt);

@override
String toString() {
  return 'Profile(id: $id, username: $username, displayName: $displayName, bio: $bio, avatarUrl: $avatarUrl, headerUrl: $headerUrl, homeCityId: $homeCityId, isVerified: $isVerified, isDemo: $isDemo, isAdmin: $isAdmin, onboardingCompleted: $onboardingCompleted, favoriteCuisines: $favoriteCuisines, tasteTags: $tasteTags, bannerStyle: $bannerStyle, tastePersonality: $tastePersonality, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$ProfileCopyWith(_Profile value, $Res Function(_Profile) _then) = __$ProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String username,@JsonKey(name: 'display_name') String displayName, String? bio,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'header_url') String? headerUrl,@JsonKey(name: 'home_city_id') String? homeCityId,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'is_demo') bool isDemo,@JsonKey(name: 'is_admin') bool isAdmin,@JsonKey(name: 'onboarding_completed') bool onboardingCompleted,@JsonKey(name: 'favorite_cuisines') List<String> favoriteCuisines,@JsonKey(name: 'taste_tags') List<String> tasteTags,@JsonKey(name: 'banner_style') String bannerStyle,@JsonKey(name: 'taste_personality') Map<String, dynamic> tastePersonality,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$ProfileCopyWithImpl<$Res>
    implements _$ProfileCopyWith<$Res> {
  __$ProfileCopyWithImpl(this._self, this._then);

  final _Profile _self;
  final $Res Function(_Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,Object? displayName = null,Object? bio = freezed,Object? avatarUrl = freezed,Object? headerUrl = freezed,Object? homeCityId = freezed,Object? isVerified = null,Object? isDemo = null,Object? isAdmin = null,Object? onboardingCompleted = null,Object? favoriteCuisines = null,Object? tasteTags = null,Object? bannerStyle = null,Object? tastePersonality = null,Object? createdAt = null,}) {
  return _then(_Profile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,headerUrl: freezed == headerUrl ? _self.headerUrl : headerUrl // ignore: cast_nullable_to_non_nullable
as String?,homeCityId: freezed == homeCityId ? _self.homeCityId : homeCityId // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isDemo: null == isDemo ? _self.isDemo : isDemo // ignore: cast_nullable_to_non_nullable
as bool,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,favoriteCuisines: null == favoriteCuisines ? _self._favoriteCuisines : favoriteCuisines // ignore: cast_nullable_to_non_nullable
as List<String>,tasteTags: null == tasteTags ? _self._tasteTags : tasteTags // ignore: cast_nullable_to_non_nullable
as List<String>,bannerStyle: null == bannerStyle ? _self.bannerStyle : bannerStyle // ignore: cast_nullable_to_non_nullable
as String,tastePersonality: null == tastePersonality ? _self._tastePersonality : tastePersonality // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
