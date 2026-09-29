// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'amount_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AmountDto _$AmountDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AmountDto', json, ($checkedConvert) {
      final val = _AmountDto(
        amount: $checkedConvert('amount', (v) => v as String),
        currency: $checkedConvert('currency', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AmountDtoToJson(_AmountDto instance) =>
    <String, dynamic>{'amount': instance.amount, 'currency': instance.currency};
