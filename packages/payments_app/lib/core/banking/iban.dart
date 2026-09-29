import 'package:equatable/equatable.dart';

/// International Bank Account Number (ISO 13616), e.g. a UAE IBAN
/// `AE07 0331 2345 6789 0123 456`.
///
/// Always holds a valid, normalised (no spaces, upper case) value. Build one
/// with [Iban.parse].
final class Iban extends Equatable {
  const Iban._(this.value);

  /// Parses [input], tolerating spaces and lower case.
  ///
  /// Throws a [FormatException] if the structure or check digits are invalid.
  factory Iban.parse(String input) {
    final normalised = input.replaceAll(' ', '').toUpperCase();
    if (!isValid(normalised)) {
      throw const FormatException('Invalid IBAN');
    }
    return Iban._(normalised);
  }

  static final RegExp _structure = RegExp(r'^[A-Z]{2}\d{2}[A-Z0-9]{11,30}$');

  final String value;

  String get countryCode => value.substring(0, 2);

  /// The last four characters, the usual way to let a user recognise an
  /// account without exposing it.
  String get lastFour => value.substring(value.length - 4);

  /// Structure check plus the ISO 7064 mod-97 checksum.
  static bool isValid(String value) =>
      _structure.hasMatch(value) &&
      _mod97('${value.substring(4)}${value.substring(0, 4)}') == 1;

  /// Remainder of the number formed by replacing letters with 10–35, computed
  /// digit by digit so it never overflows.
  static int _mod97(String input) {
    var remainder = 0;
    for (final unit in input.codeUnits) {
      final digits = unit >= 65
          ? (unit - 55).toString()
          : String.fromCharCode(unit);
      for (final digit in digits.codeUnits) {
        remainder = (remainder * 10 + (digit - 48)) % 97;
      }
    }
    return remainder;
  }

  @override
  List<Object> get props => [value];

  /// Account numbers are sensitive, so only the last four are ever logged.
  @override
  String toString() => 'Iban($countryCode•••$lastFour)';
}
