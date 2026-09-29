// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'amount_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AmountDto {

 String get amount; String get currency;
/// Create a copy of AmountDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AmountDtoCopyWith<AmountDto> get copyWith => _$AmountDtoCopyWithImpl<AmountDto>(this as AmountDto, _$identity);

  /// Serializes this AmountDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AmountDto&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,currency);

@override
String toString() {
  return 'AmountDto(amount: $amount, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $AmountDtoCopyWith<$Res>  {
  factory $AmountDtoCopyWith(AmountDto value, $Res Function(AmountDto) _then) = _$AmountDtoCopyWithImpl;
@useResult
$Res call({
 String amount, String currency
});




}
/// @nodoc
class _$AmountDtoCopyWithImpl<$Res>
    implements $AmountDtoCopyWith<$Res> {
  _$AmountDtoCopyWithImpl(this._self, this._then);

  final AmountDto _self;
  final $Res Function(AmountDto) _then;

/// Create a copy of AmountDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? currency = null,}) {
  return _then(_self.copyWith(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AmountDto].
extension AmountDtoPatterns on AmountDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AmountDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AmountDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AmountDto value)  $default,){
final _that = this;
switch (_that) {
case _AmountDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AmountDto value)?  $default,){
final _that = this;
switch (_that) {
case _AmountDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String amount,  String currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AmountDto() when $default != null:
return $default(_that.amount,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String amount,  String currency)  $default,) {final _that = this;
switch (_that) {
case _AmountDto():
return $default(_that.amount,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String amount,  String currency)?  $default,) {final _that = this;
switch (_that) {
case _AmountDto() when $default != null:
return $default(_that.amount,_that.currency);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AmountDto implements AmountDto {
  const _AmountDto({required this.amount, required this.currency});
  factory _AmountDto.fromJson(Map<String, dynamic> json) => _$AmountDtoFromJson(json);

@override final  String amount;
@override final  String currency;

/// Create a copy of AmountDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AmountDtoCopyWith<_AmountDto> get copyWith => __$AmountDtoCopyWithImpl<_AmountDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AmountDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AmountDto&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,currency);

@override
String toString() {
  return 'AmountDto(amount: $amount, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$AmountDtoCopyWith<$Res> implements $AmountDtoCopyWith<$Res> {
  factory _$AmountDtoCopyWith(_AmountDto value, $Res Function(_AmountDto) _then) = __$AmountDtoCopyWithImpl;
@override @useResult
$Res call({
 String amount, String currency
});




}
/// @nodoc
class __$AmountDtoCopyWithImpl<$Res>
    implements _$AmountDtoCopyWith<$Res> {
  __$AmountDtoCopyWithImpl(this._self, this._then);

  final _AmountDto _self;
  final $Res Function(_AmountDto) _then;

/// Create a copy of AmountDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? currency = null,}) {
  return _then(_AmountDto(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
