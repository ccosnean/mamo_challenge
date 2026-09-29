import 'package:payments_app/core/money/currency.dart';
import 'package:payments_app/core/money/money.dart';
import 'package:payments_app/features/account/domain/models/account.dart';

/// Sum of the available balances of [accounts], all in AED.
///
/// Adding AED to USD needs an exchange rate, so an account in another
/// currency throws instead of producing a wrong total.
Money totalAvailableBalance(Iterable<Account> accounts) => accounts.fold(
  const Money.zero(Currency.aed),
  (total, account) => total + account.availableBalance,
);
