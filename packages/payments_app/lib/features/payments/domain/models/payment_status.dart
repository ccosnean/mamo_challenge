/// Lifecycle of a payment after the payer decides on the request.
///
/// Follows ISO 20022 `ExternalPaymentTransactionStatus1Code`, which is also
/// the model behind Open Banking payment statuses. It keeps two facts apart:
/// the payer's decision, and whether money actually settled.
enum PaymentStatus {
  /// `RJCT`: the payer rejected the request. No money moves.
  rejected,

  /// `ACSP`: approved by the payer, settlement in progress.
  processing,

  /// `ACSC`: approved and settled. Money has moved.
  completed,

  /// Approved, but settlement failed (e.g. insufficient funds). No money
  /// moved.
  failed;

  /// Whether the payer approved the request, whatever happened next.
  bool get isApproved => this != rejected;

  /// Whether money actually moved. Only these count toward totals.
  bool get movedMoney => this == completed;
}
