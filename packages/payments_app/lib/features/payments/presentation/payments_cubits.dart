import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

final class PaymentHistoryState extends Equatable {
  const PaymentHistoryState({this.payments = const [], this.loaded = false});

  /// Most recently decided first.
  final List<Payment> payments;
  final bool loaded;

  Payment? byId(PaymentId id) => payments.where((p) => p.id == id).firstOrNull;

  @override
  List<Object> get props => [payments, loaded];
}

/// Every decided payment, live. The single source for the list, Home and
/// details, so a decision shows up everywhere at once.
class PaymentHistoryCubit extends Cubit<PaymentHistoryState> {
  PaymentHistoryCubit(PaymentsRepository repository)
    : super(const PaymentHistoryState()) {
    _subscription = repository.watchPayments().listen((payments) {
      if (!isClosed) {
        emit(PaymentHistoryState(payments: payments, loaded: true));
      }
    });
  }

  late final StreamSubscription<List<Payment>> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

/// Requests waiting on the user, oldest first. Drives the tab badge, the
/// "Waiting for you" section and the approval sheet.
class PendingRequestsCubit extends Cubit<List<PaymentRequest>> {
  PendingRequestsCubit(PaymentsRepository repository) : super(const []) {
    _subscription = repository.watchPendingRequests().listen((requests) {
      if (isClosed) return;
      if (requests.length != state.length) {
        _log.info(
          requests.isEmpty
              ? 'Inbox empty'
              : 'Inbox: ${requests.length} waiting '
                    '(${requests.map((r) => r.reference).join(', ')})',
        );
      }
      emit(requests);
    });
  }

  static final Logger _log = Logger('Inbox');

  late final StreamSubscription<List<PaymentRequest>> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
