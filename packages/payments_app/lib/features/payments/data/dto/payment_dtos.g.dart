// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PartyDto _$PartyDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PartyDto', json, ($checkedConvert) {
      final val = _PartyDto(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        iban: $checkedConvert('iban', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PartyDtoToJson(_PartyDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'iban': instance.iban,
};

_PaymentRequestDto _$PaymentRequestDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_PaymentRequestDto',
      json,
      ($checkedConvert) {
        final val = _PaymentRequestDto(
          id: $checkedConvert('id', (v) => v as String),
          reference: $checkedConvert('reference', (v) => v as String),
          payee: $checkedConvert(
            'payee',
            (v) => PartyDto.fromJson(v as Map<String, dynamic>),
          ),
          amount: $checkedConvert(
            'amount',
            (v) => AmountDto.fromJson(v as Map<String, dynamic>),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => DateTime.parse(v as String),
          ),
          note: $checkedConvert('note', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'createdAt': 'created_at', 'expiresAt': 'expires_at'},
    );

Map<String, dynamic> _$PaymentRequestDtoToJson(_PaymentRequestDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reference': instance.reference,
      'payee': instance.payee,
      'amount': instance.amount,
      'created_at': instance.createdAt.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
      'note': instance.note,
    };

_PaymentDto _$PaymentDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_PaymentDto',
  json,
  ($checkedConvert) {
    final val = _PaymentDto(
      id: $checkedConvert('id', (v) => v as String),
      reference: $checkedConvert('reference', (v) => v as String),
      payee: $checkedConvert(
        'payee',
        (v) => PartyDto.fromJson(v as Map<String, dynamic>),
      ),
      amount: $checkedConvert(
        'amount',
        (v) => AmountDto.fromJson(v as Map<String, dynamic>),
      ),
      requestedAt: $checkedConvert(
        'requested_at',
        (v) => DateTime.parse(v as String),
      ),
      status: $checkedConvert('status', (v) => v as String),
      decidedAt: $checkedConvert(
        'decided_at',
        (v) => DateTime.parse(v as String),
      ),
      note: $checkedConvert('note', (v) => v as String?),
      debtorAccountId: $checkedConvert(
        'debtor_account_id',
        (v) => v as String?,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'requestedAt': 'requested_at',
    'decidedAt': 'decided_at',
    'debtorAccountId': 'debtor_account_id',
  },
);

Map<String, dynamic> _$PaymentDtoToJson(_PaymentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reference': instance.reference,
      'payee': instance.payee,
      'amount': instance.amount,
      'requested_at': instance.requestedAt.toIso8601String(),
      'status': instance.status,
      'decided_at': instance.decidedAt.toIso8601String(),
      'note': instance.note,
      'debtor_account_id': instance.debtorAccountId,
    };
