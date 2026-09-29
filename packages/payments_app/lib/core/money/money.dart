import 'package:equatable/equatable.dart';
import 'package:payments_app/core/money/currency.dart';

/// An exact monetary amount.
///
/// Stored as an integer count of the currency's minor unit (fils for AED) so
/// sums never pick up floating point rounding errors. Arithmetic across
/// different currencies throws instead of silently producing a wrong total.
final class Money extends Equatable implements Comparable<Money> {
  const Money.minor(this.minorUnits, this.currency);

  const Money.zero(this.currency) : minorUnits = 0;

  /// Parses a decimal string as sent by the API (`"1200.00"`, `"-3.4"`)
  /// exactly, without going through a floating point number.
  ///
  /// Throws a [FormatException] for anything that isn't a plain decimal or
  /// has more decimals than [currency] allows.
  factory Money.parse(String amount, Currency currency) {
    final match = _decimal.firstMatch(amount.trim());
    final digits = currency.minorUnitDigits;
    final fraction = match?.group(3) ?? '';
    if (match == null || fraction.length > digits) {
      throw FormatException('Invalid ${currency.code} amount', amount);
    }
    final units = int.parse(
      '${match.group(2)}${fraction.padRight(digits, '0')}',
    );
    return Money.minor(match.group(1) == '-' ? -units : units, currency);
  }

  static final RegExp _decimal = RegExp(r'^(-?)(\d+)(?:\.(\d+))?$');

  final int minorUnits;
  final Currency currency;

  bool get isZero => minorUnits == 0;

  bool get isNegative => minorUnits < 0;

  Money operator +(Money other) {
    _checkSameCurrency(other);
    return Money.minor(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _checkSameCurrency(other);
    return Money.minor(minorUnits - other.minorUnits, currency);
  }

  bool operator <(Money other) => compareTo(other) < 0;

  bool operator <=(Money other) => compareTo(other) <= 0;

  bool operator >(Money other) => compareTo(other) > 0;

  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  int compareTo(Money other) {
    _checkSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  void _checkSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError.value(
        other.currency,
        'other',
        'Currency mismatch: expected ${currency.code}',
      );
    }
  }

  @override
  List<Object> get props => [minorUnits, currency];

  /// Debug representation only. User-facing text goes through a formatter.
  @override
  String toString() {
    final digits = currency.minorUnitDigits;
    final sign = isNegative ? '-' : '';
    final padded = minorUnits.abs().toString().padLeft(digits + 1, '0');
    final major = padded.substring(0, padded.length - digits);
    final minor = padded.substring(padded.length - digits);
    return '${currency.code} $sign$major${digits > 0 ? '.$minor' : ''}';
  }
}
