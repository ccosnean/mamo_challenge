// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccountDto _$AccountDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_AccountDto',
  json,
  ($checkedConvert) {
    final val = _AccountDto(
      id: $checkedConvert('id', (v) => v as String),
      companyId: $checkedConvert('company_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      iban: $checkedConvert('iban', (v) => v as String),
      availableBalance: $checkedConvert(
        'available_balance',
        (v) => AmountDto.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'companyId': 'company_id',
    'availableBalance': 'available_balance',
  },
);

Map<String, dynamic> _$AccountDtoToJson(_AccountDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'name': instance.name,
      'iban': instance.iban,
      'available_balance': instance.availableBalance,
    };
