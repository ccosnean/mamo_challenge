import 'package:flutter_test/flutter_test.dart';
import 'package:payments_app/core/banking/iban.dart';

void main() {
  group('Iban', () {
    test('parses a valid UAE IBAN, tolerating spaces and case', () {
      final iban = Iban.parse('ae07 0331 2345 6789 0123 456');

      expect(iban.value, 'AE070331234567890123456');
      expect(iban.countryCode, 'AE');
      expect(iban.lastFour, '3456');
    });

    test('rejects a wrong check digit', () {
      expect(
        () => Iban.parse('AE08 0331 2345 6789 0123 456'),
        throwsFormatException,
      );
    });

    test('rejects malformed input', () {
      expect(Iban.isValid(''), isFalse);
      expect(Iban.isValid('AE07'), isFalse);
      expect(Iban.isValid('0707033123456789012345'), isFalse);
    });

    test('never logs the full account number', () {
      final iban = Iban.parse('AE070331234567890123456');

      expect(iban.toString(), isNot(contains('0331234567890')));
    });
  });
}
