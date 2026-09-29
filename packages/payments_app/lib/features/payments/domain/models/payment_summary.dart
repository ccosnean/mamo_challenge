import 'package:equatable/equatable.dart';
import 'package:payments_app/core/money/currency.dart';
import 'package:payments_app/core/money/money.dart';
import 'package:payments_app/features/payments/domain/models/payment.dart';

/// Payment activity for one calendar month.
final class PaymentSummary extends Equatable {
  const PaymentSummary({required this.total, required this.count});

  /// Summarises [payments] for the calendar month containing [month], in the
  /// user's local time zone (a payment at 00:30 on the 1st local time belongs
  /// to the new month, even though it's still the previous month in UTC).
  ///
  /// Only completed (settled) payments count. Rejected, failed and
  /// still-processing payments haven't moved money.
  /// Payments in other currencies are left out rather than summed wrongly.
  factory PaymentSummary.forMonth(
    Iterable<Payment> payments, {
    required DateTime month,
    required Currency currency,
  }) {
    final localMonth = month.toLocal();
    var total = Money.zero(currency);
    var count = 0;

    for (final payment in payments) {
      if (!payment.status.movedMoney) continue;
      if (payment.amount.currency != currency) continue;
      final decidedAt = payment.decidedAt.toLocal();
      if (decidedAt.year != localMonth.year ||
          decidedAt.month != localMonth.month) {
        continue;
      }
      total += payment.amount;
      count++;
    }

    return PaymentSummary(total: total, count: count);
  }

  final Money total;
  final int count;

  @override
  List<Object> get props => [total, count];
}
