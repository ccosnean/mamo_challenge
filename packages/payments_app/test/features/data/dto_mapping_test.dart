import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/core/api/json_list.dart';
import 'package:payments_app/core/money/currency.dart';
import 'package:payments_app/core/money/money.dart';
import 'package:payments_app/features/account/data/dto/account_dto.dart';
import 'package:payments_app/features/payments/data/dto/payment_dtos.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

/// JSON → DTO → domain, including what gets refused on the way in.
void main() {
  final log = Logger('Test');

  Map<String, dynamic> party() => {
    'id': 'pty_1',
    'name': 'Ahmed Khalil',
    'iban': 'AE070331234567890123456',
  };

  Map<String, dynamic> payment({
    String status = 'completed',
    String amount = '1200.00',
    String iban = 'AE070331234567890123456',
  }) => {
    'id': 'pr_1',
    'reference': 'PAY-88213',
    'payee': {...party(), 'iban': iban},
    'amount': {'amount': amount, 'currency': 'AED'},
    'note': 'Design retainer',
    'requested_at': '2026-09-28T10:10:00.000Z',
    'status': status,
    'decided_at': '2026-09-28T10:32:00.000Z',
    'debtor_account_id': status == 'rejected' ? null : 'acc_1',
  };

  test('a payment maps to the domain exactly', () {
    final mapped = PaymentDto.fromJson(payment()).toDomain();

    expect(mapped.id, const PaymentId('pr_1'));
    expect(mapped.amount, const Money.minor(120000, Currency.aed));
    expect(mapped.status, PaymentStatus.completed);
    expect(mapped.decidedAt, DateTime.utc(2026, 9, 28, 10, 32));
    expect(mapped.decidedAt.isUtc, isTrue);
    expect(mapped.payee.account.lastFour, '3456');
    expect(mapped.debtorAccountId, 'acc_1');
  });

  test('a pending request maps to the domain', () {
    final mapped = PaymentRequestDto.fromJson({
      'id': 'pr_2',
      'reference': 'PAY-10001',
      'payee': party(),
      'amount': {'amount': '15.5', 'currency': 'AED'},
      'note': null,
      'created_at': '2026-09-28T10:00:00Z',
      'expires_at': '2026-09-29T10:00:00Z',
    }).toDomain();

    expect(mapped.amount, const Money.minor(1550, Currency.aed));
    expect(mapped.note, isNull);
    expect(mapped.expiresAt, DateTime.utc(2026, 9, 29, 10));
  });

  test('accounts map balances and IBANs', () {
    final mapped = AccountDto.fromJson({
      'id': 'acc_1',
      'company_id': 'co_1',
      'name': 'Current account',
      'iban': 'AE070331234567890123456',
      'available_balance': {'amount': '12460.25', 'currency': 'AED'},
    }).toDomain();

    expect(mapped.availableBalance, const Money.minor(1246025, Currency.aed));
  });

  group('refused on the way in', () {
    List<Payment> parse(List<Map<String, dynamic>> items) => parseDataList(
      {'data': items},
      fromJson: PaymentDto.fromJson,
      toDomain: (dto) => dto.toDomain(),
      log: log,
    );

    test('an unknown status, a bad IBAN or a bad amount drops the item', () {
      final parsed = parse([
        payment(),
        payment(status: 'settled-ish'),
        payment(iban: 'AE000331234567890123456'),
        payment(amount: '12.345'),
        payment(amount: '1e3'),
      ]);

      expect(parsed, hasLength(1));
    });

    test('a missing field drops the item', () {
      expect(parse([payment()..remove('reference')]), isEmpty);
    });

    test('a body that is not an envelope is an error', () {
      expect(
        () => parseDataList(
          [payment()],
          fromJson: PaymentDto.fromJson,
          toDomain: (dto) => dto.toDomain(),
          log: log,
        ),
        throwsFormatException,
      );
    });
  });
}
