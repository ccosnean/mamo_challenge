/// Opaque identifier of a payment request and of the payment it becomes.
///
/// A distinct type so an id can't be mixed up with a human-facing reference
/// like `PAY-88213`.
extension type const PaymentId(String value) implements Object {}
