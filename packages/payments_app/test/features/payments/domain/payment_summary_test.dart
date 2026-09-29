import 'package:flutter_test/flutter_test.dart';
import 'package:payments_app/core/banking/iban.dart';
import 'package:payments_app/core/money/currency.dart';
import 'package:payments_app/core/money/money.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

Payment _payment({
  required int fils,
  required DateTime decidedAtLocal,
  PaymentStatus status = PaymentStatus.completed,
}) {
  final decidedAt = decidedAtLocal.toUtc();
  return Payment(
    id: PaymentId('id-$fils-${decidedAt.microsecondsSinceEpoch}'),
    reference: 'PAY-00000',
    payee: Party(
      id: 'p',
      name: 'Ahmed Khalil',
      account: Iban.parse('AE07 0331 2345 6789 0123 456'),
    ),
    amount: Money.minor(fils, Currency.aed),
    requestedAt: decidedAt,
    status: status,
    decidedAt: decidedAt,
    debtorAccountId: status.isApproved ? 'account' : null,
  );
}

void main() {
  group('PaymentSummary.forMonth', () {
    final september = DateTime(2026, 9, 28, 12);

    test('sums approved payments of the month', () {
      final summary = PaymentSummary.forMonth(
        [
          _payment(fils: 120000, decidedAtLocal: DateTime(2026, 9, 10)),
          _payment(fils: 34000, decidedAtLocal: DateTime(2026, 9, 12)),
        ],
        month: september,
        currency: Currency.aed,
      );

      expect(
        summary,
        const PaymentSummary(
          total: Money.minor(154000, Currency.aed),
          count: 2,
        ),
      );
    });

    test('counts only settled payments: the rest moved no money', () {
      final summary = PaymentSummary.forMonth(
        [
          _payment(fils: 120000, decidedAtLocal: DateTime(2026, 9, 10)),
          for (final status in [
            PaymentStatus.rejected,
            PaymentStatus.processing,
            PaymentStatus.failed,
          ])
            _payment(
              fils: 90000,
              decidedAtLocal: DateTime(2026, 9, 11),
              status: status,
            ),
        ],
        month: september,
        currency: Currency.aed,
      );

      expect(summary.total, const Money.minor(120000, Currency.aed));
      expect(summary.count, 1);
    });

    test('uses local calendar month boundaries', () {
      final summary = PaymentSummary.forMonth(
        [
          _payment(fils: 100, decidedAtLocal: DateTime(2026, 8, 31, 23, 59)),
          _payment(fils: 200, decidedAtLocal: DateTime(2026, 9)),
          _payment(fils: 300, decidedAtLocal: DateTime(2026, 9, 30, 23, 59)),
          _payment(fils: 400, decidedAtLocal: DateTime(2026, 10)),
        ],
        month: september,
        currency: Currency.aed,
      );

      expect(summary.total, const Money.minor(500, Currency.aed));
      expect(summary.count, 2);
    });

    test('is zero when nothing happened this month', () {
      final summary = PaymentSummary.forMonth(
        const [],
        month: september,
        currency: Currency.aed,
      );

      expect(summary.total.isZero, isTrue);
      expect(summary.count, 0);
    });
  });
}
