import 'package:flutter_test/flutter_test.dart';
import 'package:payments_app/core/logging/log_redactor.dart';

void main() {
  final redactor = LogRedactor();

  group('LogRedactor', () {
    test('masks IBANs, keeping country and last four', () {
      expect(
        redactor.redact('to AE070331234567890123456 ok'),
        'to AE••3456 ok',
      );
      expect(
        redactor.redact('to AE07 0331 2345 6789 0123 456'),
        isNot(contains('0331')),
      );
    });

    test('masks OAuth access tokens', () {
      expect(
        redactor.redact('Bearer at_Zk3v9Qm2_x-LpA7rT0yW'),
        'Bearer at_•••',
      );
    });

    test('masks card numbers', () {
      expect(redactor.redact('pan 4111 1111 1111 1111'), 'pan <card>');
      expect(redactor.redact('pan 4111111111111111'), 'pan <card>');
    });

    test('masks emails and phone numbers', () {
      expect(redactor.redact('mail a.b+c@mamo.co'), 'mail <email>');
      expect(redactor.redact('call +971 50 123 4567'), 'call <phone>');
    });

    test('masks amounts next to a currency code', () {
      expect(redactor.redact('AED 1,200.00 sent'), 'AED ••• sent');
      expect(redactor.redact('Money(AED 340.50)'), 'Money(AED •••)');
    });

    test('keeps references, ids, statuses and times readable', () {
      const line =
          'PAY-88213 approved → completed, expires '
          '2026-09-29T12:00:00.000Z (2 pending) id:3f2a9c1b';

      expect(redactor.redact(line), line);
    });
  });
}
