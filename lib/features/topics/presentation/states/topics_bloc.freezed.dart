// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'topics_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TopicsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopicsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TopicsEvent()';
}


}

/// @nodoc
class $TopicsEventCopyWith<$Res>  {
$TopicsEventCopyWith(TopicsEvent _, $Res Function(TopicsEvent) __);
}


/// Adds pattern-matching-related methods to [TopicsEvent].
extension TopicsEventPatterns on TopicsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Started value)?  started,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Started() when started != null:
return started(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Started value)  started,}){
final _that = this;
switch (_that) {
case _Started():
return started(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Started value)?  started,}){
final _that = this;
switch (_that) {
case _Started() when started != null:
return started(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Started() when started != null:
return started();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,}) {final _that = this;
switch (_that) {
case _Started():
return started();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,}) {final _that = this;
switch (_that) {
case _Started() when started != null:
return started();case _:
  return null;

}
}

}

/// @nodoc


class _Started implements TopicsEvent {
  const _Started();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Started);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TopicsEvent.started()';
}


}




/// @nodoc
mixin _$TopicsState {

 BlocStatus<List<TopicEntity>> get topicsState;
/// Create a copy of TopicsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopicsStateCopyWith<TopicsState> get copyWith => _$TopicsStateCopyWithImpl<TopicsState>(this as TopicsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopicsState&&(identical(other.topicsState, topicsState) || other.topicsState == topicsState));
}


@override
int get hashCode => Object.hash(runtimeType,topicsState);

@override
String toString() {
  return 'TopicsState(topicsState: $topicsState)';
}


}

/// @nodoc
abstract mixin class $TopicsStateCopyWith<$Res>  {
  factory $TopicsStateCopyWith(TopicsState value, $Res Function(TopicsState) _then) = _$TopicsStateCopyWithImpl;
@useResult
$Res call({
 BlocStatus<List<TopicEntity>> topicsState
});


$BlocStatusCopyWith<List<TopicEntity>, $Res> get topicsState;

}
/// @nodoc
class _$TopicsStateCopyWithImpl<$Res>
    implements $TopicsStateCopyWith<$Res> {
  _$TopicsStateCopyWithImpl(this._self, this._then);

  final TopicsState _self;
  final $Res Function(TopicsState) _then;

/// Create a copy of TopicsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? topicsState = null,}) {
  return _then(_self.copyWith(
topicsState: null == topicsState ? _self.topicsState : topicsState // ignore: cast_nullable_to_non_nullable
as BlocStatus<List<TopicEntity>>,
  ));
}
/// Create a copy of TopicsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BlocStatusCopyWith<List<TopicEntity>, $Res> get topicsState {
  
  return $BlocStatusCopyWith<List<TopicEntity>, $Res>(_self.topicsState, (value) {
    return _then(_self.copyWith(topicsState: value));
  });
}
}


/// Adds pattern-matching-related methods to [TopicsState].
extension TopicsStatePatterns on TopicsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopicsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopicsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopicsState value)  $default,){
final _that = this;
switch (_that) {
case _TopicsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopicsState value)?  $default,){
final _that = this;
switch (_that) {
case _TopicsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BlocStatus<List<TopicEntity>> topicsState)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopicsState() when $default != null:
return $default(_that.topicsState);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BlocStatus<List<TopicEntity>> topicsState)  $default,) {final _that = this;
switch (_that) {
case _TopicsState():
return $default(_that.topicsState);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BlocStatus<List<TopicEntity>> topicsState)?  $default,) {final _that = this;
switch (_that) {
case _TopicsState() when $default != null:
return $default(_that.topicsState);case _:
  return null;

}
}

}

/// @nodoc


class _TopicsState implements TopicsState {
  const _TopicsState({this.topicsState = const BlocStatus<List<TopicEntity>>.initial()});
  

@override@JsonKey() final  BlocStatus<List<TopicEntity>> topicsState;

/// Create a copy of TopicsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopicsStateCopyWith<_TopicsState> get copyWith => __$TopicsStateCopyWithImpl<_TopicsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopicsState&&(identical(other.topicsState, topicsState) || other.topicsState == topicsState));
}


@override
int get hashCode => Object.hash(runtimeType,topicsState);

@override
String toString() {
  return 'TopicsState(topicsState: $topicsState)';
}


}

/// @nodoc
abstract mixin class _$TopicsStateCopyWith<$Res> implements $TopicsStateCopyWith<$Res> {
  factory _$TopicsStateCopyWith(_TopicsState value, $Res Function(_TopicsState) _then) = __$TopicsStateCopyWithImpl;
@override @useResult
$Res call({
 BlocStatus<List<TopicEntity>> topicsState
});


@override $BlocStatusCopyWith<List<TopicEntity>, $Res> get topicsState;

}
/// @nodoc
class __$TopicsStateCopyWithImpl<$Res>
    implements _$TopicsStateCopyWith<$Res> {
  __$TopicsStateCopyWithImpl(this._self, this._then);

  final _TopicsState _self;
  final $Res Function(_TopicsState) _then;

/// Create a copy of TopicsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? topicsState = null,}) {
  return _then(_TopicsState(
topicsState: null == topicsState ? _self.topicsState : topicsState // ignore: cast_nullable_to_non_nullable
as BlocStatus<List<TopicEntity>>,
  ));
}

/// Create a copy of TopicsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BlocStatusCopyWith<List<TopicEntity>, $Res> get topicsState {
  
  return $BlocStatusCopyWith<List<TopicEntity>, $Res>(_self.topicsState, (value) {
    return _then(_self.copyWith(topicsState: value));
  });
}
}

// dart format on
