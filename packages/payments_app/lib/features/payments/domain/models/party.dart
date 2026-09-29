import 'package:equatable/equatable.dart';
import 'package:payments_app/core/banking/iban.dart';

/// A person or business taking part in a payment.
///
/// Mirrors ISO 20022 `PartyIdentification` (`Nm`) plus the party's account
/// (`CdtrAcct` / `DbtrAcct`). The name is a single field, as in every payment
/// standard. Splitting it into first/last breaks for mononyms, many Arabic
/// names and businesses.
final class Party extends Equatable {
  Party({required this.id, required this.name, required this.account})
    : assert(
        name.trim().isNotEmpty && name.length <= maxNameLength,
        'Name must be 1–$maxNameLength characters',
      );

  /// ISO 20022 `Max140Text` limit for names.
  static const int maxNameLength = 140;

  final String id;

  /// Full name as the account holder is known, e.g. `Ahmed Khalil` or
  /// `Studio Nine LLC`.
  final String name;

  final Iban account;

  @override
  List<Object> get props => [id, name, account];

  /// Names are personal data, so they are kept out of logs and crash reports.
  @override
  String toString() => 'Party(id: $id, name: <redacted>, account: $account)';
}
