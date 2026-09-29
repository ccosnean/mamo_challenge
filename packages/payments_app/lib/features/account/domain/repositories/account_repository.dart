import 'package:payments_app/features/account/domain/models/account.dart';

/// The signed-in user's accounts and balances.
abstract interface class AccountRepository {
  /// Emits once the accounts are loaded, then after every refresh. Empty
  /// while signed out.
  Stream<List<Account>> watchAccounts();

  /// Re-reads the accounts from the server (e.g. after a payment).
  Future<void> refresh();
}
