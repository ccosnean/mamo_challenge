// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_dtos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PartyDto {

 String get id; String get name; String get iban;
/// Create a copy of PartyDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PartyDtoCopyWith<PartyDto> get copyWith => _$PartyDtoCopyWithImpl<PartyDto>(this as PartyDto, _$identity);

  /// Serializes this PartyDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PartyDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iban, iban) || other.iban == iban));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iban);



}

/// @nodoc
abstract mixin class $PartyDtoCopyWith<$Res>  {
  factory $PartyDtoCopyWith(PartyDto value, $Res Function(PartyDto) _then) = _$PartyDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String iban
});




}
/// @nodoc
class _$PartyDtoCopyWithImpl<$Res>
    implements $PartyDtoCopyWith<$Res> {
  _$PartyDtoCopyWithImpl(this._self, this._then);

  final PartyDto _self;
  final $Res Function(PartyDto) _then;

/// Create a copy of PartyDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? iban = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iban: null == iban ? _self.iban : iban // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PartyDto].
extension PartyDtoPatterns on PartyDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PartyDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PartyDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PartyDto value)  $default,){
final _that = this;
switch (_that) {
case _PartyDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PartyDto value)?  $default,){
final _that = this;
switch (_that) {
case _PartyDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String iban)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PartyDto() when $default != null:
return $default(_that.id,_that.name,_that.iban);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String iban)  $default,) {final _that = this;
switch (_that) {
case _PartyDto():
return $default(_that.id,_that.name,_that.iban);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String iban)?  $default,) {final _that = this;
switch (_that) {
case _PartyDto() when $default != null:
return $default(_that.id,_that.name,_that.iban);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PartyDto extends PartyDto {
  const _PartyDto({required this.id, required this.name, required this.iban}): super._();
  factory _PartyDto.fromJson(Map<String, dynamic> json) => _$PartyDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String iban;

/// Create a copy of PartyDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PartyDtoCopyWith<_PartyDto> get copyWith => __$PartyDtoCopyWithImpl<_PartyDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PartyDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PartyDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iban, iban) || other.iban == iban));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iban);



}

/// @nodoc
abstract mixin class _$PartyDtoCopyWith<$Res> implements $PartyDtoCopyWith<$Res> {
  factory _$PartyDtoCopyWith(_PartyDto value, $Res Function(_PartyDto) _then) = __$PartyDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String iban
});




}
/// @nodoc
class __$PartyDtoCopyWithImpl<$Res>
    implements _$PartyDtoCopyWith<$Res> {
  __$PartyDtoCopyWithImpl(this._self, this._then);

  final _PartyDto _self;
  final $Res Function(_PartyDto) _then;

/// Create a copy of PartyDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? iban = null,}) {
  return _then(_PartyDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iban: null == iban ? _self.iban : iban // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PaymentRequestDto {

 String get id; String get reference; PartyDto get payee; AmountDto get amount; DateTime get createdAt; DateTime get expiresAt; String? get note;
/// Create a copy of PaymentRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentRequestDtoCopyWith<PaymentRequestDto> get copyWith => _$PaymentRequestDtoCopyWithImpl<PaymentRequestDto>(this as PaymentRequestDto, _$identity);

  /// Serializes this PaymentRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentRequestDto&&(identical(other.id, id) || other.id == id)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.payee, payee) || other.payee == payee)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,reference,payee,amount,createdAt,expiresAt,note);



}

/// @nodoc
abstract mixin class $PaymentRequestDtoCopyWith<$Res>  {
  factory $PaymentRequestDtoCopyWith(PaymentRequestDto value, $Res Function(PaymentRequestDto) _then) = _$PaymentRequestDtoCopyWithImpl;
@useResult
$Res call({
 String id, String reference, PartyDto payee, AmountDto amount, DateTime createdAt, DateTime expiresAt, String? note
});


$PartyDtoCopyWith<$Res> get payee;$AmountDtoCopyWith<$Res> get amount;

}
/// @nodoc
class _$PaymentRequestDtoCopyWithImpl<$Res>
    implements $PaymentRequestDtoCopyWith<$Res> {
  _$PaymentRequestDtoCopyWithImpl(this._self, this._then);

  final PaymentRequestDto _self;
  final $Res Function(PaymentRequestDto) _then;

/// Create a copy of PaymentRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? reference = null,Object? payee = null,Object? amount = null,Object? createdAt = null,Object? expiresAt = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,payee: null == payee ? _self.payee : payee // ignore: cast_nullable_to_non_nullable
as PartyDto,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as AmountDto,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PaymentRequestDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PartyDtoCopyWith<$Res> get payee {
  
  return $PartyDtoCopyWith<$Res>(_self.payee, (value) {
    return _then(_self.copyWith(payee: value));
  });
}/// Create a copy of PaymentRequestDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AmountDtoCopyWith<$Res> get amount {
  
  return $AmountDtoCopyWith<$Res>(_self.amount, (value) {
    return _then(_self.copyWith(amount: value));
  });
}
}


/// Adds pattern-matching-related methods to [PaymentRequestDto].
extension PaymentRequestDtoPatterns on PaymentRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _PaymentRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String reference,  PartyDto payee,  AmountDto amount,  DateTime createdAt,  DateTime expiresAt,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentRequestDto() when $default != null:
return $default(_that.id,_that.reference,_that.payee,_that.amount,_that.createdAt,_that.expiresAt,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String reference,  PartyDto payee,  AmountDto amount,  DateTime createdAt,  DateTime expiresAt,  String? note)  $default,) {final _that = this;
switch (_that) {
case _PaymentRequestDto():
return $default(_that.id,_that.reference,_that.payee,_that.amount,_that.createdAt,_that.expiresAt,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String reference,  PartyDto payee,  AmountDto amount,  DateTime createdAt,  DateTime expiresAt,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _PaymentRequestDto() when $default != null:
return $default(_that.id,_that.reference,_that.payee,_that.amount,_that.createdAt,_that.expiresAt,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentRequestDto extends PaymentRequestDto {
  const _PaymentRequestDto({required this.id, required this.reference, required this.payee, required this.amount, required this.createdAt, required this.expiresAt, this.note}): super._();
  factory _PaymentRequestDto.fromJson(Map<String, dynamic> json) => _$PaymentRequestDtoFromJson(json);

@override final  String id;
@override final  String reference;
@override final  PartyDto payee;
@override final  AmountDto amount;
@override final  DateTime createdAt;
@override final  DateTime expiresAt;
@override final  String? note;

/// Create a copy of PaymentRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentRequestDtoCopyWith<_PaymentRequestDto> get copyWith => __$PaymentRequestDtoCopyWithImpl<_PaymentRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentRequestDto&&(identical(other.id, id) || other.id == id)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.payee, payee) || other.payee == payee)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,reference,payee,amount,createdAt,expiresAt,note);



}

/// @nodoc
abstract mixin class _$PaymentRequestDtoCopyWith<$Res> implements $PaymentRequestDtoCopyWith<$Res> {
  factory _$PaymentRequestDtoCopyWith(_PaymentRequestDto value, $Res Function(_PaymentRequestDto) _then) = __$PaymentRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String reference, PartyDto payee, AmountDto amount, DateTime createdAt, DateTime expiresAt, String? note
});


@override $PartyDtoCopyWith<$Res> get payee;@override $AmountDtoCopyWith<$Res> get amount;

}
/// @nodoc
class __$PaymentRequestDtoCopyWithImpl<$Res>
    implements _$PaymentRequestDtoCopyWith<$Res> {
  __$PaymentRequestDtoCopyWithImpl(this._self, this._then);

  final _PaymentRequestDto _self;
  final $Res Function(_PaymentRequestDto) _then;

/// Create a copy of PaymentRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? reference = null,Object? payee = null,Object? amount = null,Object? createdAt = null,Object? expiresAt = null,Object? note = freezed,}) {
  return _then(_PaymentRequestDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,payee: null == payee ? _self.payee : payee // ignore: cast_nullable_to_non_nullable
as PartyDto,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as AmountDto,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PaymentRequestDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PartyDtoCopyWith<$Res> get payee {
  
  return $PartyDtoCopyWith<$Res>(_self.payee, (value) {
    return _then(_self.copyWith(payee: value));
  });
}/// Create a copy of PaymentRequestDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AmountDtoCopyWith<$Res> get amount {
  
  return $AmountDtoCopyWith<$Res>(_self.amount, (value) {
    return _then(_self.copyWith(amount: value));
  });
}
}


/// @nodoc
mixin _$PaymentDto {

 String get id; String get reference; PartyDto get payee; AmountDto get amount; DateTime get requestedAt; String get status; DateTime get decidedAt; String? get note; String? get debtorAccountId;
/// Create a copy of PaymentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentDtoCopyWith<PaymentDto> get copyWith => _$PaymentDtoCopyWithImpl<PaymentDto>(this as PaymentDto, _$identity);

  /// Serializes this PaymentDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.payee, payee) || other.payee == payee)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.note, note) || other.note == note)&&(identical(other.debtorAccountId, debtorAccountId) || other.debtorAccountId == debtorAccountId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,reference,payee,amount,requestedAt,status,decidedAt,note,debtorAccountId);



}

/// @nodoc
abstract mixin class $PaymentDtoCopyWith<$Res>  {
  factory $PaymentDtoCopyWith(PaymentDto value, $Res Function(PaymentDto) _then) = _$PaymentDtoCopyWithImpl;
@useResult
$Res call({
 String id, String reference, PartyDto payee, AmountDto amount, DateTime requestedAt, String status, DateTime decidedAt, String? note, String? debtorAccountId
});


$PartyDtoCopyWith<$Res> get payee;$AmountDtoCopyWith<$Res> get amount;

}
/// @nodoc
class _$PaymentDtoCopyWithImpl<$Res>
    implements $PaymentDtoCopyWith<$Res> {
  _$PaymentDtoCopyWithImpl(this._self, this._then);

  final PaymentDto _self;
  final $Res Function(PaymentDto) _then;

/// Create a copy of PaymentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? reference = null,Object? payee = null,Object? amount = null,Object? requestedAt = null,Object? status = null,Object? decidedAt = null,Object? note = freezed,Object? debtorAccountId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,payee: null == payee ? _self.payee : payee // ignore: cast_nullable_to_non_nullable
as PartyDto,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as AmountDto,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,decidedAt: null == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,debtorAccountId: freezed == debtorAccountId ? _self.debtorAccountId : debtorAccountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PaymentDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PartyDtoCopyWith<$Res> get payee {
  
  return $PartyDtoCopyWith<$Res>(_self.payee, (value) {
    return _then(_self.copyWith(payee: value));
  });
}/// Create a copy of PaymentDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AmountDtoCopyWith<$Res> get amount {
  
  return $AmountDtoCopyWith<$Res>(_self.amount, (value) {
    return _then(_self.copyWith(amount: value));
  });
}
}


/// Adds pattern-matching-related methods to [PaymentDto].
extension PaymentDtoPatterns on PaymentDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentDto value)  $default,){
final _that = this;
switch (_that) {
case _PaymentDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentDto value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String reference,  PartyDto payee,  AmountDto amount,  DateTime requestedAt,  String status,  DateTime decidedAt,  String? note,  String? debtorAccountId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentDto() when $default != null:
return $default(_that.id,_that.reference,_that.payee,_that.amount,_that.requestedAt,_that.status,_that.decidedAt,_that.note,_that.debtorAccountId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String reference,  PartyDto payee,  AmountDto amount,  DateTime requestedAt,  String status,  DateTime decidedAt,  String? note,  String? debtorAccountId)  $default,) {final _that = this;
switch (_that) {
case _PaymentDto():
return $default(_that.id,_that.reference,_that.payee,_that.amount,_that.requestedAt,_that.status,_that.decidedAt,_that.note,_that.debtorAccountId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String reference,  PartyDto payee,  AmountDto amount,  DateTime requestedAt,  String status,  DateTime decidedAt,  String? note,  String? debtorAccountId)?  $default,) {final _that = this;
switch (_that) {
case _PaymentDto() when $default != null:
return $default(_that.id,_that.reference,_that.payee,_that.amount,_that.requestedAt,_that.status,_that.decidedAt,_that.note,_that.debtorAccountId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentDto extends PaymentDto {
  const _PaymentDto({required this.id, required this.reference, required this.payee, required this.amount, required this.requestedAt, required this.status, required this.decidedAt, this.note, this.debtorAccountId}): super._();
  factory _PaymentDto.fromJson(Map<String, dynamic> json) => _$PaymentDtoFromJson(json);

@override final  String id;
@override final  String reference;
@override final  PartyDto payee;
@override final  AmountDto amount;
@override final  DateTime requestedAt;
@override final  String status;
@override final  DateTime decidedAt;
@override final  String? note;
@override final  String? debtorAccountId;

/// Create a copy of PaymentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentDtoCopyWith<_PaymentDto> get copyWith => __$PaymentDtoCopyWithImpl<_PaymentDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.payee, payee) || other.payee == payee)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.note, note) || other.note == note)&&(identical(other.debtorAccountId, debtorAccountId) || other.debtorAccountId == debtorAccountId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,reference,payee,amount,requestedAt,status,decidedAt,note,debtorAccountId);



}

/// @nodoc
abstract mixin class _$PaymentDtoCopyWith<$Res> implements $PaymentDtoCopyWith<$Res> {
  factory _$PaymentDtoCopyWith(_PaymentDto value, $Res Function(_PaymentDto) _then) = __$PaymentDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String reference, PartyDto payee, AmountDto amount, DateTime requestedAt, String status, DateTime decidedAt, String? note, String? debtorAccountId
});


@override $PartyDtoCopyWith<$Res> get payee;@override $AmountDtoCopyWith<$Res> get amount;

}
/// @nodoc
class __$PaymentDtoCopyWithImpl<$Res>
    implements _$PaymentDtoCopyWith<$Res> {
  __$PaymentDtoCopyWithImpl(this._self, this._then);

  final _PaymentDto _self;
  final $Res Function(_PaymentDto) _then;

/// Create a copy of PaymentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? reference = null,Object? payee = null,Object? amount = null,Object? requestedAt = null,Object? status = null,Object? decidedAt = null,Object? note = freezed,Object? debtorAccountId = freezed,}) {
  return _then(_PaymentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,payee: null == payee ? _self.payee : payee // ignore: cast_nullable_to_non_nullable
as PartyDto,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as AmountDto,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,decidedAt: null == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,debtorAccountId: freezed == debtorAccountId ? _self.debtorAccountId : debtorAccountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PaymentDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PartyDtoCopyWith<$Res> get payee {
  
  return $PartyDtoCopyWith<$Res>(_self.payee, (value) {
    return _then(_self.copyWith(payee: value));
  });
}/// Create a copy of PaymentDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AmountDtoCopyWith<$Res> get amount {
  
  return $AmountDtoCopyWith<$Res>(_self.amount, (value) {
    return _then(_self.copyWith(amount: value));
  });
}
}

// dart format on
