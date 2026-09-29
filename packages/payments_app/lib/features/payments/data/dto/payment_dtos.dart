import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:payments_app/core/api/amount_dto.dart';
import 'package:payments_app/core/banking/iban.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

part 'payment_dtos.freezed.dart';
part 'payment_dtos.g.dart';

@freezed
abstract class PartyDto with _$PartyDto {
  const factory PartyDto({
    required String id,
    required String name,
    required String iban,
  }) = _PartyDto;

  factory PartyDto.fromJson(Map<String, dynamic> json) =>
      _$PartyDtoFromJson(json);

  const PartyDto._();

  /// Names and account numbers are personal data.
  @override
  String toString() => 'PartyDto(id: $id)';
}

/// An item of `GET /payment-requests`.
@freezed
abstract class PaymentRequestDto with _$PaymentRequestDto {
  const factory PaymentRequestDto({
    required String id,
    required String reference,
    required PartyDto payee,
    required AmountDto amount,
    required DateTime createdAt,
    required DateTime expiresAt,
    String? note,
  }) = _PaymentRequestDto;

  factory PaymentRequestDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentRequestDtoFromJson(json);

  const PaymentRequestDto._();

  @override
  String toString() => 'PaymentRequestDto(id: $id, reference: $reference)';
}

/// An item of `GET /payments`, and the body of approve/reject responses.
@freezed
abstract class PaymentDto with _$PaymentDto {
  const factory PaymentDto({
    required String id,
    required String reference,
    required PartyDto payee,
    required AmountDto amount,
    required DateTime requestedAt,
    required String status,
    required DateTime decidedAt,
    String? note,
    String? debtorAccountId,
  }) = _PaymentDto;

  factory PaymentDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentDtoFromJson(json);

  const PaymentDto._();

  @override
  String toString() => 'PaymentDto(id: $id, reference: $reference)';
}

extension PartyDtoMapper on PartyDto {
  Party toDomain() => Party(id: id, name: name, account: Iban.parse(iban));
}

extension PaymentRequestDtoMapper on PaymentRequestDto {
  PaymentRequest toDomain() => PaymentRequest(
    id: PaymentId(id),
    reference: reference,
    payee: payee.toDomain(),
    amount: amount.toDomain(),
    createdAt: createdAt.toUtc(),
    expiresAt: expiresAt.toUtc(),
    note: note,
  );
}

extension PaymentDtoMapper on PaymentDto {
  /// Throws a [FormatException] for a status the app doesn't know, rather
  /// than showing a payment in the wrong state.
  Payment toDomain() => Payment(
    id: PaymentId(id),
    reference: reference,
    payee: payee.toDomain(),
    amount: amount.toDomain(),
    requestedAt: requestedAt.toUtc(),
    note: note,
    status: _status(status),
    decidedAt: decidedAt.toUtc(),
    debtorAccountId: debtorAccountId,
  );

  static PaymentStatus _status(String value) => switch (value) {
    'completed' => PaymentStatus.completed,
    'processing' => PaymentStatus.processing,
    'rejected' => PaymentStatus.rejected,
    'failed' => PaymentStatus.failed,
    _ => throw FormatException('Unknown payment status', value),
  };
}
