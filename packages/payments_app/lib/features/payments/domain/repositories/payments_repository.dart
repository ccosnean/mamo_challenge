import 'package:payments_app/features/payments/domain/models/payment.dart';
import 'package:payments_app/features/payments/domain/models/payment_id.dart';
import 'package:payments_app/features/payments/domain/models/payment_request.dart';

/// Source of truth for the user's Request-to-Pay inbox and payment history.
///
/// The user is always the payer. Payees send requests, and the user approves
/// (ISO 20022 `ACCP`) or rejects (`RJCT`) them.
///
/// Both watch streams emit once loaded and again after every change, so
/// every screen observing them stays in sync. Emitted lists are
/// unmodifiable. Both are empty while signed out.
abstract interface class PaymentsRepository {
  /// Unexpired requests waiting on the user's decision, oldest first. Kept
  /// fresh by polling while signed in.
  Stream<List<PaymentRequest>> watchPendingRequests();

  /// Decided payments, most recently decided first.
  Stream<List<Payment>> watchPayments();

  /// Re-reads pending requests and history now, instead of waiting for the
  /// next poll.
  Future<void> refresh();

  /// Approves a pending request, paying it from the user's account
  /// [fromAccountId], and returns the resulting payment, whose status
  /// reflects settlement (`processing`, `completed` or `failed`).
  ///
  /// Throws a `PaymentsException` if the request is unknown, expired, was
  /// already decided, the account can't cover it, or the service is
  /// unavailable.
  Future<Payment> approve(PaymentId id, {required String fromAccountId});

  /// Rejects a pending request and returns the resulting `rejected` payment.
  ///
  /// Throws a `PaymentsException` if the request is unknown, expired, was
  /// already decided, or the service is unavailable.
  Future<Payment> reject(PaymentId id);
}
