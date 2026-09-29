import 'package:flutter_test/flutter_test.dart';
import 'package:payments_app/core/money/currency.dart';
import 'package:payments_app/core/money/money.dart';

void main() {
  group('Money', () {
    test('adds exactly in minor units', () {
      // 0.1 + 0.2 in doubles is 0.30000000000000004. Not here.
      const a = Money.minor(10, Currency.aed);
      const b = Money.minor(20, Currency.aed);

      expect(a + b, const Money.minor(30, Currency.aed));
    });

    test('subtracts and compares', () {
      const a = Money.minor(120000, Currency.aed);
      const b = Money.minor(34000, Currency.aed);

      expect(a - b, const Money.minor(86000, Currency.aed));
      expect(a.compareTo(b), greaterThan(0));
      expect((b - a).isNegative, isTrue);
    });

    test('zero is zero', () {
      expect(const Money.zero(Currency.aed).isZero, isTrue);
    });

    test('toString renders major and minor units', () {
      expect(const Money.minor(120000, Currency.aed).toString(), 'AED 1200.00');
      expect(const Money.minor(5, Currency.aed).toString(), 'AED 0.05');
      expect(const Money.minor(-340, Currency.aed).toString(), 'AED -3.40');
    });
  });

  group('Money.parse', () {
    Money parse(String value) => Money.parse(value, Currency.aed);

    test('reads decimal strings exactly', () {
      expect(parse('1200.00'), const Money.minor(120000, Currency.aed));
      expect(parse('15.5'), const Money.minor(1550, Currency.aed));
      expect(parse('7'), const Money.minor(700, Currency.aed));
      expect(parse('-3.40'), const Money.minor(-340, Currency.aed));
      expect(parse('0.10'), const Money.minor(10, Currency.aed));
    });

    test('refuses anything but a plain decimal', () {
      for (final bad in ['', '12.345', '1e3', '1,200.00', '.5', 'abc']) {
        expect(() => parse(bad), throwsFormatException, reason: bad);
      }
    });

    test('refuses unsupported currencies', () {
      expect(() => Currency.fromCode('USD'), throwsFormatException);
    });
  });
}
