import 'package:equatable/equatable.dart';
import 'package:payments_app/core/money/money.dart';
import 'package:payments_app/features/payments/domain/models/party.dart';
import 'package:payments_app/features/payments/domain/models/payment_id.dart';

/// An incoming Request-to-Pay waiting on the user's decision.
///
/// The payee (ISO 20022 creditor) asks the user, who is the payer (debtor),
/// to pay [amount]. Mirrors the ISO 20022 `pain.013` creditor payment
/// activation request.
///
/// A separate type from `Payment` on purpose: screens that need a decided
/// payment (list, details) can't be handed a pending request, because the
/// compiler won't allow it.
final class PaymentRequest extends Equatable {
  PaymentRequest({
    required this.id,
    required this.reference,
    required this.payee,
    required this.amount,
    required this.createdAt,
    required this.expiresAt,
    this.note,
  }) : assert(
         createdAt.isUtc && expiresAt.isUtc,
         'Timestamps are stored in UTC',
       ),
       assert(
         expiresAt.isAfter(createdAt),
         'A request must expire after it is created',
       ),
       assert(!amount.isNegative && !amount.isZero, 'Amount must be positive'),
       assert(
         note == null || note.length <= maxNoteLength,
         'Note must be at most $maxNoteLength characters',
       );

  /// ISO 20022 `Max140Text` limit for unstructured remittance information.
  static const int maxNoteLength = 140;

  final PaymentId id;

  /// End-to-end reference (ISO 20022 `EndToEndId`), e.g. `PAY-88213`. It
  /// travels unchanged with the payment and is shown to both parties, so it's
  /// safe to display unmasked.
  final String reference;

  /// Who gets paid (ISO 20022 `Cdtr` + `CdtrAcct`).
  final Party payee;

  /// Instructed amount (ISO 20022 `InstdAmt`).
  final Money amount;

  /// When the payee sent the request (ISO 20022 `CreDtTm`).
  final DateTime createdAt;

  /// After this the request can no longer be approved (ISO 20022 `XpryDt`).
  final DateTime expiresAt;

  /// Free text from the payee (ISO 20022 `RmtInf/Ustrd`), e.g.
  /// `Design retainer`.
  final String? note;

  @override
  List<Object?> get props => [
    id,
    reference,
    payee,
    amount,
    createdAt,
    expiresAt,
    note,
  ];

  @override
  String toString() => 'PaymentRequest(id: $id, reference: $reference)';
}
