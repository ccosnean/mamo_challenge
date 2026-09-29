import 'package:flutter_test/flutter_test.dart';
import 'package:payments_app/core/banking/iban.dart';
import 'package:payments_app/core/money/currency.dart';
import 'package:payments_app/core/money/money.dart';
import 'package:payments_app/features/account/domain/domain.dart';

Account _account(int fils) => Account(
  id: 'a$fils',
  companyId: 'c',
  name: 'Account',
  iban: Iban.parse('AE070331234567890123456'),
  availableBalance: Money.minor(fils, Currency.aed),
);

void main() {
  test('sums available balances exactly', () {
    expect(
      totalAvailableBalance([
        _account(1246025),
        _account(585000),
        _account(15000),
      ]),
      const Money.minor(1846025, Currency.aed),
    );
  });

  test('is zero without accounts', () {
    expect(totalAvailableBalance(const []).isZero, isTrue);
  });

  test('canCover compares against the available balance', () {
    final account = _account(15000);

    expect(account.canCover(const Money.minor(15000, Currency.aed)), isTrue);
    expect(account.canCover(const Money.minor(15001, Currency.aed)), isFalse);
  });
}
