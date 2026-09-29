import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/features/account/domain/domain.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

sealed class ApprovalEvent {
  const ApprovalEvent();
}

/// The sheet was unlocked with device auth: show payee and amount.
final class ApprovalRevealed extends ApprovalEvent {
  const ApprovalRevealed();
}

/// The sheet locked again (e.g. the app went to the background).
final class ApprovalConcealed extends ApprovalEvent {
  const ApprovalConcealed();
}

final class ApprovalAccountSelected extends ApprovalEvent {
  const ApprovalAccountSelected(this.accountId);

  final String accountId;
}

final class ApprovalApproveRequested extends ApprovalEvent {
  const ApprovalApproveRequested();
}

final class ApprovalRejectRequested extends ApprovalEvent {
  const ApprovalRejectRequested();
}

/// The request stopped being pending while it was on screen (e.g. it
/// expired, or was decided elsewhere).
final class ApprovalRequestWithdrawn extends ApprovalEvent {
  const ApprovalRequestWithdrawn();
}

final class _AccountsChanged extends ApprovalEvent {
  const _AccountsChanged(this.accounts);

  final List<Account> accounts;
}

enum ApprovalActivity { idle, approving, rejecting }

/// Something the page explains inline. The request stays open.
enum ApprovalNotice { none, insufficientFunds, serviceUnavailable }

/// How the request left the sheet. Null while it's still there.
enum ApprovalOutcome {
  approved,
  rejected,
  expired,
  alreadyDecided,

  /// The session ended (401); the app is returning to sign in.
  sessionEnded,
}

final class ApprovalState extends Equatable {
  const ApprovalState({
    required this.request,
    this.revealed = false,
    this.activity = ApprovalActivity.idle,
    this.notice = ApprovalNotice.none,
    this.accounts = const [],
    this.selectedAccountId,
    this.outcome,
  });

  final PaymentRequest request;

  /// Payee and amount are shown only while the sheet is unlocked.
  final bool revealed;
  final ApprovalActivity activity;
  final ApprovalNotice notice;
  final List<Account> accounts;
  final String? selectedAccountId;
  final ApprovalOutcome? outcome;

  bool get busy => activity != ApprovalActivity.idle;

  Account? get selectedAccount => selectedAccountId == null
      ? null
      : accounts.where((a) => a.id == selectedAccountId).firstOrNull;

  /// The selected account can't cover the amount.
  bool get selectedCannotCover {
    final account = selectedAccount;
    return account != null && !account.canCover(request.amount);
  }

  bool get canApprove =>
      revealed &&
      !busy &&
      outcome == null &&
      (selectedAccount?.canCover(request.amount) ?? false);

  bool get canReject => !busy && outcome == null;

  ApprovalState copyWith({
    bool? revealed,
    ApprovalActivity? activity,
    ApprovalNotice? notice,
    List<Account>? accounts,
    String? selectedAccountId,
    ApprovalOutcome? outcome,
  }) => ApprovalState(
    request: request,
    revealed: revealed ?? this.revealed,
    activity: activity ?? this.activity,
    notice: notice ?? this.notice,
    accounts: accounts ?? this.accounts,
    selectedAccountId: selectedAccountId ?? this.selectedAccountId,
    outcome: outcome ?? this.outcome,
  );

  @override
  List<Object?> get props => [
    request,
    revealed,
    activity,
    notice,
    accounts,
    selectedAccountId,
    outcome,
  ];
}

/// One request's page in the approval sheet: masked until the sheet is
/// unlocked, then an account picker, then approve or reject.
///
/// Device auth isn't done here: the sheet unlocks once for all its pages
/// (see `ApprovalQueueCubit`) and tells each page with [ApprovalRevealed].
///
/// Every action is ignored while another is in flight, so double taps can't
/// send two decisions. The repository is the authority on funds: a refusal
/// (AM04) comes back as a notice and the request stays open.
class ApprovalBloc extends Bloc<ApprovalEvent, ApprovalState> {
  ApprovalBloc({
    required PaymentRequest request,
    required PaymentsRepository payments,
    required AccountRepository accounts,
    bool revealed = false,
  }) : _payments = payments,
       super(ApprovalState(request: request)) {
    on<ApprovalRevealed>(_onRevealed);
    on<ApprovalConcealed>(_onConcealed);
    on<ApprovalAccountSelected>(_onAccountSelected);
    on<ApprovalApproveRequested>(_onApproveRequested);
    on<ApprovalRejectRequested>(_onRejectRequested);
    on<ApprovalRequestWithdrawn>(_onRequestWithdrawn);
    on<_AccountsChanged>(_onAccountsChanged);
    _accountsSubscription = accounts.watchAccounts().listen(
      (accounts) => add(_AccountsChanged(accounts)),
    );
    // The amount is masked by the log redactor; the payee is never logged.
    _log.info(
      '$_ref: on screen, ${request.amount}, '
      'expires ${request.expiresAt.toIso8601String()}',
    );
    if (revealed) add(const ApprovalRevealed());
  }

  String get _ref => state.request.reference;

  static final Logger _log = Logger('ApprovalBloc');

  final PaymentsRepository _payments;
  late final StreamSubscription<List<Account>> _accountsSubscription;

  void _onRevealed(ApprovalRevealed event, Emitter<ApprovalState> emit) {
    if (state.revealed || state.outcome != null) return;
    emit(
      state.copyWith(
        revealed: true,
        selectedAccountId:
            state.selectedAccountId ?? _defaultAccountId(state.accounts),
      ),
    );
    _logSelection('revealed');
  }

  void _onConcealed(ApprovalConcealed event, Emitter<ApprovalState> emit) {
    if (!state.revealed) return;
    emit(
      ApprovalState(
        request: state.request,
        activity: state.activity,
        notice: state.notice,
        accounts: state.accounts,
        selectedAccountId: state.selectedAccountId,
        outcome: state.outcome,
      ),
    );
  }

  void _onAccountSelected(
    ApprovalAccountSelected event,
    Emitter<ApprovalState> emit,
  ) {
    if (!state.revealed || state.busy) return;
    emit(
      state.copyWith(
        selectedAccountId: event.accountId,
        notice: ApprovalNotice.none,
      ),
    );
    _logSelection('account picked');
  }

  Future<void> _onApproveRequested(
    ApprovalApproveRequested event,
    Emitter<ApprovalState> emit,
  ) async {
    final account = state.selectedAccount;
    if (!state.canApprove || account == null) {
      _log.fine('$_ref: approve ignored (not allowed right now)');
      return;
    }
    _log.info(
      '$_ref: approving ${state.request.amount} from ${account.iban.value}',
    );
    emit(
      state.copyWith(
        activity: ApprovalActivity.approving,
        notice: ApprovalNotice.none,
      ),
    );
    await _decide(
      emit,
      () => _payments.approve(state.request.id, fromAccountId: account.id),
      success: ApprovalOutcome.approved,
    );
  }

  Future<void> _onRejectRequested(
    ApprovalRejectRequested event,
    Emitter<ApprovalState> emit,
  ) async {
    if (!state.canReject) {
      _log.fine('$_ref: reject ignored (busy or decided)');
      return;
    }
    _log.info('$_ref: rejecting');
    emit(
      state.copyWith(
        activity: ApprovalActivity.rejecting,
        notice: ApprovalNotice.none,
      ),
    );
    await _decide(
      emit,
      () => _payments.reject(state.request.id),
      success: ApprovalOutcome.rejected,
    );
  }

  void _onRequestWithdrawn(
    ApprovalRequestWithdrawn event,
    Emitter<ApprovalState> emit,
  ) {
    // A decision in flight will report its own outcome.
    if (state.busy || state.outcome != null) return;
    _log.info('$_ref: no longer pending');
    emit(state.copyWith(outcome: ApprovalOutcome.expired));
  }

  void _onAccountsChanged(_AccountsChanged event, Emitter<ApprovalState> emit) {
    final selectedStillExists = event.accounts.any(
      (a) => a.id == state.selectedAccountId,
    );
    emit(
      state.copyWith(
        accounts: event.accounts,
        selectedAccountId: selectedStillExists || !state.revealed
            ? state.selectedAccountId
            : _defaultAccountId(event.accounts),
      ),
    );
  }

  Future<void> _decide(
    Emitter<ApprovalState> emit,
    Future<Payment> Function() decision, {
    required ApprovalOutcome success,
  }) async {
    try {
      await decision();
      _log.info('$_ref: ${success.name}');
      emit(
        state.copyWith(activity: ApprovalActivity.idle, outcome: success),
      );
    } on InsufficientFundsException {
      _log.warning('$_ref: refused, insufficient funds (AM04)');
      emit(
        state.copyWith(
          activity: ApprovalActivity.idle,
          notice: ApprovalNotice.insufficientFunds,
        ),
      );
    } on PaymentRequestExpiredException {
      _log.warning('$_ref: expired before the decision');
      emit(state.copyWith(outcome: ApprovalOutcome.expired));
    } on PaymentRequestNotFoundException {
      emit(state.copyWith(outcome: ApprovalOutcome.expired));
    } on PaymentAlreadyDecidedException {
      _log.warning('$_ref: already decided elsewhere');
      emit(state.copyWith(outcome: ApprovalOutcome.alreadyDecided));
    } on PaymentsUnauthorizedException {
      _log.warning('$_ref: session ended during the decision');
      emit(state.copyWith(outcome: ApprovalOutcome.sessionEnded));
    } on PaymentsUnavailableException {
      _log.warning('$_ref: bank unreachable, nothing sent');
      emit(
        state.copyWith(
          activity: ApprovalActivity.idle,
          notice: ApprovalNotice.serviceUnavailable,
        ),
      );
    } on Object catch (error, stackTrace) {
      _log.severe('$_ref: decision failed unexpectedly', error, stackTrace);
      emit(
        state.copyWith(
          activity: ApprovalActivity.idle,
          notice: ApprovalNotice.serviceUnavailable,
        ),
      );
    }
  }

  /// IBAN and balance are masked by the log redactor.
  void _logSelection(String why) {
    final account = state.selectedAccount;
    if (account == null) return;
    _log.fine(
      '$_ref: $why, paying from ${account.id} (${account.iban.value}, '
      'available ${account.availableBalance}'
      '${state.selectedCannotCover ? ', not enough' : ''})',
    );
  }

  /// First account that can cover the amount, else the first account.
  String? _defaultAccountId(List<Account> accounts) {
    if (accounts.isEmpty) return null;
    return (accounts
                .where((a) => a.canCover(state.request.amount))
                .firstOrNull ??
            accounts.first)
        .id;
  }

  @override
  Future<void> close() async {
    await _accountsSubscription.cancel();
    return super.close();
  }
}
