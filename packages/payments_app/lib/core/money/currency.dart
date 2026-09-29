/// ISO 4217 currencies the app can hold amounts in.
enum Currency {
  aed(code: 'AED', minorUnitDigits: 2);

  const Currency({required this.code, required this.minorUnitDigits});

  /// ISO 4217 alphabetic code, e.g. `AED`.
  final String code;

  /// Decimal places of the minor unit (2 for AED: 1 AED = 100 fils).
  final int minorUnitDigits;

  /// The currency for an ISO 4217 [code]. Throws a [FormatException] for a
  /// currency the app doesn't support, rather than guessing.
  static Currency fromCode(String code) {
    for (final currency in values) {
      if (currency.code == code) return currency;
    }
    throw FormatException('Unsupported currency', code);
  }
}
