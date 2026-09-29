import 'package:payments_app/core/banking/iban.dart';

/// Partial masks for personal and financial data shown before the user has
/// authenticated.
abstract final class Masking {
  static const String _dots = '••••';

  /// `Ahmed Khalil` → `A•••• K.`, `Haddad Consulting FZ-LLC` → `H•••• F.`,
  /// `Cher` → `C••••`. Fixed-width, so the length of the name isn't leaked.
  static String name(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return _dots;
    final first = _initial(parts.first);
    if (parts.length == 1) return '$first$_dots';
    return '$first$_dots ${_initial(parts.last)}.';
  }

  /// `AE07 •••• 3456`: the country, check digits and last four, the usual way
  /// to let someone recognise an account without exposing it.
  static String iban(Iban iban) =>
      '${iban.value.substring(0, 4)} $_dots ${iban.lastFour}';

  static String _initial(String word) =>
      String.fromCharCodes(word.runes.take(1)).toUpperCase();
}
