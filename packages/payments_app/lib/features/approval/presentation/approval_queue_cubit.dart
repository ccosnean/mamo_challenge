import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/core/device_auth/device_authenticator.dart';
import 'package:payments_app/features/account/domain/domain.dart';
import 'package:payments_app/features/approval/presentation/approval_bloc.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

enum QueueLock { locked, authenticating, unlocked }

/// Why the last unlock attempt didn't unlock.
enum UnlockNotice { none, failed, unavailable }

/// What happened while the sheet was open.
final class ApprovalQueueResult extends Equatable {
  const ApprovalQueueResult(this.outcomes);

  final List<ApprovalOutcome> outcomes;

  int count(ApprovalOutcome outcome) =>
      outcomes.where((o) => o == outcome).length;

  bool get anyApproved => outcomes.contains(ApprovalOutcome.approved);

  @override
  List<Object> get props => [outcomes];
}

final class ApprovalQueueState extends Equatable {
  const ApprovalQueueState({
    this.requests = const [],
    this.index = 0,
    this.lock = QueueLock.locked,
    this.unlockNotice = UnlockNotice.none,
    this.outcomes = const [],
    this.finished = false,
  });

  /// One page per request, in arrival order.
  final List<PaymentRequest> requests;

  /// The page on screen.
  final int index;
  final QueueLock lock;
  final UnlockNotice unlockNotice;

  /// How each decided page ended, in order.
  final List<ApprovalOutcome> outcomes;

  /// Every page is decided: the sheet should close.
  final bool finished;

  bool get unlocked => lock == QueueLock.unlocked;

  PaymentRequest? get current =>
      requests.isEmpty ? null : requests[index.clamp(0, requests.length - 1)];

  ApprovalQueueState copyWith({
    List<PaymentRequest>? requests,
    int? index,
    QueueLock? lock,
    UnlockNotice? unlockNotice,
    List<ApprovalOutcome>? outcomes,
    bool? finished,
  }) => ApprovalQueueState(
    requests: requests ?? this.requests,
    index: index ?? this.index,
    lock: lock ?? this.lock,
    unlockNotice: unlockNotice ?? this.unlockNotice,
    outcomes: outcomes ?? this.outcomes,
    finished: finished ?? this.finished,
  );

  @override
  List<Object> get props => [
    requests,
    index,
    lock,
    unlockNotice,
    outcomes,
    finished,
  ];
}

/// The approval sheet as a whole: every pending request as a page, one
/// unlock for all of them.
///
/// - Requests that arrive while the sheet is open become new pages.
/// - Device auth runs at most once per sheet: once it passes, every page
///   (including later ones) shows its details. It locks again on [lock],
///   e.g. when the app goes to the background.
/// - Each page has its own [ApprovalBloc]. A decided page leaves; after the
///   last one the state is [ApprovalQueueState.finished].
class ApprovalQueueCubit extends Cubit<ApprovalQueueState> {
  ApprovalQueueCubit({
    required PaymentsRepository payments,
    required AccountRepository accounts,
    required DeviceAuthenticator authenticator,
    required List<PaymentRequest> pending,
    PaymentId? initial,
  }) : _payments = payments,
       _accounts = accounts,
       _authenticator = authenticator,
       super(const ApprovalQueueState()) {
    pending.forEach(_addPage);
    final start = initial == null
        ? 0
        : pending
              .indexWhere((r) => r.id == initial)
              .clamp(0, pending.isEmpty ? 0 : pending.length - 1);
    emit(state.copyWith(requests: List.unmodifiable(pending), index: start));
    _log.info('Opened with ${pending.length} request(s)');
    _pendingSubscription = payments.watchPendingRequests().listen(_onPending);
  }

  static final Logger _log = Logger('ApprovalQueue');

  final PaymentsRepository _payments;
  final AccountRepository _accounts;
  final DeviceAuthenticator _authenticator;

  final Map<PaymentId, ApprovalBloc> _pages = {};
  final Map<PaymentId, StreamSubscription<ApprovalState>> _pageSubscriptions =
      {};
  late final StreamSubscription<List<PaymentRequest>> _pendingSubscription;

  /// The page bloc for [request]. Owned by this cubit.
  ApprovalBloc pageFor(PaymentRequest request) => _pages[request.id]!;

  void showPage(int index) {
    if (state.requests.isEmpty) return;
    final target = index.clamp(0, state.requests.length - 1);
    if (target != state.index) emit(state.copyWith(index: target));
  }

  void next() => showPage(state.index + 1);

  void previous() => showPage(state.index - 1);

  /// Device auth, once for the whole sheet.
  Future<void> unlock() async {
    if (state.lock != QueueLock.locked) return;
    emit(
      state.copyWith(
        lock: QueueLock.authenticating,
        unlockNotice: UnlockNotice.none,
      ),
    );
    _log.info('Face ID requested to reveal ${state.requests.length} page(s)');
    final result = await _authenticator.authenticate(
      reason: state.requests.length == 1
          ? 'Reveal payment ${state.requests.single.reference}'
          : 'Reveal ${state.requests.length} payment requests',
    );
    _log.info('Face ID ${result.name}');
    if (isClosed) return;

    switch (result) {
      case DeviceAuthResult.success:
        emit(state.copyWith(lock: QueueLock.unlocked));
        for (final page in _pages.values) {
          page.add(const ApprovalRevealed());
        }
      case DeviceAuthResult.failed:
        emit(
          state.copyWith(
            lock: QueueLock.locked,
            unlockNotice: UnlockNotice.failed,
          ),
        );
      case DeviceAuthResult.unavailable:
        emit(
          state.copyWith(
            lock: QueueLock.locked,
            unlockNotice: UnlockNotice.unavailable,
          ),
        );
      case DeviceAuthResult.cancelled:
        emit(state.copyWith(lock: QueueLock.locked));
    }
  }

  /// Hides every page's details again.
  void lock() {
    if (state.lock != QueueLock.unlocked) return;
    _log.info('Locked again');
    emit(state.copyWith(lock: QueueLock.locked));
    for (final page in _pages.values) {
      page.add(const ApprovalConcealed());
    }
  }

  void _onPending(List<PaymentRequest> pending) {
    if (isClosed || state.finished) return;
    final pendingIds = {for (final r in pending) r.id};

    // Pages whose request stopped being pending, not because of a decision
    // made here (a page's own decision reports itself).
    for (final request in state.requests) {
      if (!pendingIds.contains(request.id)) {
        _pages[request.id]?.add(const ApprovalRequestWithdrawn());
      }
    }

    final added = [
      for (final request in pending)
        if (!_pages.containsKey(request.id)) request,
    ];
    if (added.isEmpty) return;
    added.forEach(_addPage);
    _log.info('${added.length} new request(s) joined the sheet');
    emit(
      state.copyWith(
        requests: List.unmodifiable([...state.requests, ...added]),
      ),
    );
  }

  void _addPage(PaymentRequest request) {
    final page = ApprovalBloc(
      request: request,
      payments: _payments,
      accounts: _accounts,
      revealed: state.unlocked,
    );
    _pages[request.id] = page;
    _pageSubscriptions[request.id] = page.stream.listen((pageState) {
      final outcome = pageState.outcome;
      if (outcome != null) _onDecided(request.id, outcome);
    });
  }

  void _onDecided(PaymentId id, ApprovalOutcome outcome) {
    if (isClosed || !_pages.containsKey(id)) return;
    unawaited(_pageSubscriptions.remove(id)?.cancel());
    unawaited(_pages.remove(id)?.close());

    final removedAt = state.requests.indexWhere((r) => r.id == id);
    final remaining = List<PaymentRequest>.unmodifiable(
      state.requests.where((r) => r.id != id),
    );
    // Stay on the same position, so the next request slides into view.
    final index = removedAt < state.index ? state.index - 1 : state.index;
    _log.info('Page decided (${outcome.name}); ${remaining.length} left');
    emit(
      state.copyWith(
        requests: remaining,
        index: remaining.isEmpty ? 0 : index.clamp(0, remaining.length - 1),
        outcomes: List.unmodifiable([...state.outcomes, outcome]),
        finished: remaining.isEmpty,
      ),
    );
  }

  ApprovalQueueResult get result => ApprovalQueueResult(state.outcomes);

  @override
  Future<void> close() async {
    await _pendingSubscription.cancel();
    for (final subscription in _pageSubscriptions.values) {
      await subscription.cancel();
    }
    for (final page in _pages.values) {
      await page.close();
    }
    return super.close();
  }
}
