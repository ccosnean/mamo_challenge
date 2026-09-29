import 'dart:async';

import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/core/money/currency.dart';
import 'package:payments_app/core/money/money.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

final class HomeState extends Equatable {
  const HomeState({
    required this.month,
    this.summary = const PaymentSummary(
      total: Money.zero(Currency.aed),
      count: 0,
    ),
    this.rejectedThisMonth = 0,
    this.recent = const [],
    this.loaded = false,
  });

  /// Any moment in the month being summarised (local time).
  final DateTime month;

  /// Money that actually moved this month.
  final PaymentSummary summary;

  /// Shown next to the total so it's clear rejections aren't counted.
  final int rejectedThisMonth;

  /// Latest approved payments, most recent first.
  final List<Payment> recent;

  final bool loaded;

  @override
  List<Object> get props => [month, summary, rejectedThisMonth, recent, loaded];
}

/// This month's summary and the latest approved payments.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(PaymentsRepository repository, {Clock clock = const Clock()})
    : _clock = clock,
      super(HomeState(month: clock.now())) {
    _subscription = repository.watchPayments().listen(_onPayments);
  }

  static const int recentCount = 5;
  static final Logger _log = Logger('HomeCubit');

  final Clock _clock;
  late final StreamSubscription<List<Payment>> _subscription;

  void _onPayments(List<Payment> payments) {
    if (isClosed) return;
    final month = _clock.now();
    bool inMonth(Payment p) {
      final decided = p.decidedAt.toLocal();
      return decided.year == month.year && decided.month == month.month;
    }

    final state = HomeState(
      month: month,
      summary: PaymentSummary.forMonth(
        payments,
        month: month,
        currency: Currency.aed,
      ),
      rejectedThisMonth: payments
          .where((p) => p.status == PaymentStatus.rejected && inMonth(p))
          .length,
      recent: payments
          .where((p) => p.status.isApproved)
          .take(recentCount)
          .toList(growable: false),
      loaded: true,
    );
    // The total is masked by the log redactor.
    _log.fine(
      'Summary: ${state.summary.count} payments, ${state.summary.total} '
      '(${state.rejectedThisMonth} rejected, not counted)',
    );
    emit(state);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
