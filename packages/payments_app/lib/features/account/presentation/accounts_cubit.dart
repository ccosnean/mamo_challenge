import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/core/money/money.dart';
import 'package:payments_app/features/account/domain/domain.dart';

final class AccountsState extends Equatable {
  const AccountsState({this.accounts = const [], this.loaded = false});

  final List<Account> accounts;
  final bool loaded;

  /// Total across accounts, for the top bar.
  Money get total => totalAvailableBalance(accounts);

  Account? byId(String? id) =>
      id == null ? null : accounts.where((a) => a.id == id).firstOrNull;

  @override
  List<Object> get props => [accounts, loaded];
}

/// The company's accounts, live. Balances update as payments are approved.
class AccountsCubit extends Cubit<AccountsState> {
  AccountsCubit(AccountRepository repository) : super(const AccountsState()) {
    _subscription = repository.watchAccounts().listen((accounts) {
      if (isClosed) return;
      final state = AccountsState(accounts: accounts, loaded: true);
      _log.fine('${accounts.length} accounts, total ${state.total}');
      emit(state);
    });
  }

  static final Logger _log = Logger('AccountsCubit');

  late final StreamSubscription<List<Account>> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

/// Whether balances are hidden, e.g. when using the app in public. Lasts for
/// the session.
class BalanceVisibilityCubit extends Cubit<bool> {
  BalanceVisibilityCubit() : super(false);

  void toggle() {
    Logger('Balances').info(state ? 'Balances shown' : 'Balances hidden');
    emit(!state);
  }
}
