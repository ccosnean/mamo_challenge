import 'package:intl/intl.dart';
import 'package:payments_app/core/money/money.dart';

/// Display formatting for money. The currency code is rendered separately
/// (smaller, muted), so these return the number only.
abstract final class MoneyFormat {
  static final NumberFormat _grouped = NumberFormat('#,##0', 'en_US');

  /// Grouped, with the currency's minor digits: `1,200.00`, `-3.40`.
  ///
  /// Works on the integer minor units throughout, so it's exact for any
  /// amount.
  static String amount(Money money) {
    final digits = money.currency.minorUnitDigits;
    final units = money.minorUnits.abs();
    final divisor = _pow10(digits);
    final major = _grouped.format(units ~/ divisor);
    final sign = money.isNegative ? '-' : '';
    if (digits == 0) return '$sign$major';
    final minor = (units % divisor).toString().padLeft(digits, '0');
    return '$sign$major.$minor';
  }

  /// Same shape for every amount, so a hidden value never reveals how many
  /// digits it has.
  static const String masked = '••,•••.••';

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
