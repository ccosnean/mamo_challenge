import 'package:equatable/equatable.dart';
import 'package:payments_app/core/money/money.dart';
import 'package:payments_app/features/payments/domain/models/party.dart';
import 'package:payments_app/features/payments/domain/models/payment_id.dart';
import 'package:payments_app/features/payments/domain/models/payment_status.dart';

/// A payment request the user has decided on, and what happened to it since.
///
/// Mirrors the ISO 20022 `pain.014` status report for the request, together
/// with the resulting payment's transaction status.
final class Payment extends Equatable {
  Payment({
    required this.id,
    required this.reference,
    required this.payee,
    required this.amount,
    required this.requestedAt,
    required this.status,
    required this.decidedAt,
    this.note,
    this.debtorAccountId,
  }) : assert(
         status == PaymentStatus.rejected || debtorAccountId != null,
         'An approved payment is always paid from an account',
       ),
       assert(
         requestedAt.isUtc && decidedAt.isUtc,
         'Timestamps are stored in UTC',
       );

  final PaymentId id;

  /// End-to-end reference (ISO 20022 `EndToEndId`).
  final String reference;

  /// Who gets paid (ISO 20022 `Cdtr`). The user is always the payer.
  final Party payee;

  /// Instructed amount (ISO 20022 `InstdAmt`).
  final Money amount;

  /// When the payee sent the request (ISO 20022 `CreDtTm`).
  final DateTime requestedAt;

  /// Free text from the payee (ISO 20022 `RmtInf/Ustrd`).
  final String? note;

  final PaymentStatus status;

  /// When the user approved or rejected (ISO 20022 `AccptncDtTm`). Lists are
  /// ordered by it and monthly totals are bucketed by it.
  final DateTime decidedAt;

  /// The user's account the money left from (ISO 20022 `DbtrAcct`). Null for
  /// rejected payments, which moved no money.
  final String? debtorAccountId;

  @override
  List<Object?> get props => [
    id,
    reference,
    payee,
    amount,
    requestedAt,
    note,
    status,
    decidedAt,
    debtorAccountId,
  ];

  @override
  String toString() =>
      'Payment(id: $id, reference: $reference, status: ${status.name})';
}
