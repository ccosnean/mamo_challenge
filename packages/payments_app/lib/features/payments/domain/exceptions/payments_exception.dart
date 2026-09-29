import 'package:payments_app/features/payments/domain/models/payment_id.dart';

/// Failures the payments repository can report. Sealed so the UI handles
/// every case explicitly.
sealed class PaymentsException implements Exception {
  const PaymentsException();
}

/// The request was already approved or rejected, e.g. by a double tap or on
/// another device.
final class PaymentAlreadyDecidedException extends PaymentsException {
  const PaymentAlreadyDecidedException(this.id);

  final PaymentId id;

  @override
  String toString() => 'PaymentAlreadyDecidedException($id)';
}

/// No pending request exists with this id.
final class PaymentRequestNotFoundException extends PaymentsException {
  const PaymentRequestNotFoundException(this.id);

  final PaymentId id;

  @override
  String toString() => 'PaymentRequestNotFoundException($id)';
}

/// The request expired before the user decided on it.
final class PaymentRequestExpiredException extends PaymentsException {
  const PaymentRequestExpiredException(this.id);

  final PaymentId id;

  @override
  String toString() => 'PaymentRequestExpiredException($id)';
}

/// The account can't cover the amount (ISO 20022 reason `AM04`). The request
/// stays pending, so it can be approved after a top-up.
final class InsufficientFundsException extends PaymentsException {
  const InsufficientFundsException(this.id);

  final PaymentId id;

  @override
  String toString() => 'InsufficientFundsException($id)';
}

/// The session is no longer valid (HTTP 401). The app is signing out.
final class PaymentsUnauthorizedException extends PaymentsException {
  const PaymentsUnauthorizedException();

  @override
  String toString() => 'PaymentsUnauthorizedException()';
}

/// A transient failure (network, server). Safe to retry.
final class PaymentsUnavailableException extends PaymentsException {
  const PaymentsUnavailableException();

  @override
  String toString() => 'PaymentsUnavailableException()';
}
