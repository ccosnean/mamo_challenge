import 'package:payments_app/core/money/currency.dart';

/// Last line of defence against sensitive data reaching log output.
///
/// Call sites are expected to log only ids, references and statuses, and
/// models already redact themselves in `toString`. This scrubs anything that
/// still slips through (e.g. an exception message quoting an IBAN) before a
/// line is written anywhere.
///
/// Over-redaction is preferred to leaks: a false positive costs a less useful
/// log line, while a false negative leaks personal or financial data.
final class LogRedactor {
  LogRedactor({Iterable<Currency> currencies = Currency.values})
    : _rules = [
        // OAuth access tokens (`at_…`): credentials, never printable.
        (RegExp(r'\bat_[A-Za-z0-9_-]{8,}'), (_) => 'at_•••'),
        // Card numbers (PAN): 13–19 digits, optionally grouped.
        (RegExp(r'\b(?:\d[ -]?){12,18}\d\b'), (_) => '<card>'),
        // IBANs: keep the country and the last four, like the UI does.
        (
          RegExp(r'\b([A-Z]{2})\d{2}(?: ?[A-Z0-9]){7,26}([A-Z0-9]{4})\b'),
          (m) => '${m[1]}••${m[2]}',
        ),
        (RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+'), (_) => '<email>'),
        (RegExp(r'\+\d[\d -]{6,}\d'), (_) => '<phone>'),
        // Amounts next to a known currency code, e.g. `AED 1,200.00`. Limited
        // to real codes so references like `PAY-88213` survive.
        (
          RegExp(
            '\\b(${currencies.map((c) => c.code).join('|')})'
            r' ?-?\d[\d,]*(?:\.\d+)?',
          ),
          (m) => '${m[1]} •••',
        ),
      ];

  final List<(RegExp, String Function(Match))> _rules;

  String redact(String input) {
    var output = input;
    for (final (pattern, replace) in _rules) {
      output = output.replaceAllMapped(pattern, replace);
    }
    return output;
  }
}
