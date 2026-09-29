import 'package:flutter_test/flutter_test.dart';
import 'package:payments_app/core/banking/iban.dart';
import 'package:payments_app/core/format/date_format.dart';
import 'package:payments_app/core/format/masking.dart';
import 'package:payments_app/core/format/money_format.dart';
import 'package:payments_app/core/money/currency.dart';
import 'package:payments_app/core/money/money.dart';

void main() {
  group('MoneyFormat.amount', () {
    String format(int fils) =>
        MoneyFormat.amount(Money.minor(fils, Currency.aed));

    test('groups thousands and keeps two decimals', () {
      expect(format(120000), '1,200.00');
      expect(format(1846025), '18,460.25');
      expect(format(5), '0.05');
      expect(format(0), '0.00');
    });

    test('is exact for negative amounts', () {
      expect(format(-340), '-3.40');
      expect(format(-120001), '-1,200.01');
    });

    test('is exact for very large amounts', () {
      expect(format(999999999999), '9,999,999,999.99');
    });

    test('the mask has a fixed shape, whatever the amount', () {
      expect(MoneyFormat.masked, '••,•••.••');
    });
  });

  group('Masking', () {
    test('names keep only the initials', () {
      expect(Masking.name('Ahmed Khalil'), 'A•••• K.');
      expect(Masking.name('Haddad Consulting FZ-LLC'), 'H•••• F.');
      expect(Masking.name('  sara   mansour '), 'S•••• M.');
      expect(Masking.name('Cher'), 'C••••');
    });

    test('never reveals the length of a name', () {
      expect(
        Masking.name('Al Li').length,
        Masking.name('Alexandria Konstantinopoulos').length,
      );
    });

    test('IBANs keep the country, check digits and last four', () {
      expect(
        Masking.iban(Iban.parse('AE070331234567890123456')),
        'AE07 •••• 3456',
      );
    });
  });

  group('DateLabels', () {
    final now = DateTime(2026, 9, 28, 15);

    test('groups by local day', () {
      expect(DateLabels.day(DateTime(2026, 9, 28, 0, 5), now: now), 'Today');
      expect(DateLabels.day(DateTime(2026, 9, 27, 23), now: now), 'Yesterday');
      expect(DateLabels.day(DateTime(2026, 9, 21), now: now), '21 September');
      expect(
        DateLabels.day(DateTime(2025, 12, 31), now: now),
        '31 December 2025',
      );
    });

    test('short labels include the time for recent days', () {
      expect(
        DateLabels.short(DateTime(2026, 9, 28, 14, 32), now: now),
        'Today, 14:32',
      );
      expect(DateLabels.short(DateTime(2026, 9, 12), now: now), '12 Sep');
    });

    test('remaining time rounds down to whole units', () {
      expect(
        DateLabels.remaining(
          now.add(const Duration(hours: 23, minutes: 59)),
          now: now,
        ),
        '23 h',
      );
      expect(
        DateLabels.remaining(now.add(const Duration(minutes: 45)), now: now),
        '45 min',
      );
    });
  });
}
