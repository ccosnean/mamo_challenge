import 'package:equatable/equatable.dart';
import 'package:payments_app/core/banking/iban.dart';
import 'package:payments_app/core/money/money.dart';

/// A bank account owned by the user's company. Payments are debited from it.
final class Account extends Equatable {
  const Account({
    required this.id,
    required this.companyId,
    required this.name,
    required this.iban,
    required this.availableBalance,
  });

  final String id;
  final String companyId;

  /// Display name, e.g. `Current account`.
  final String name;

  final Iban iban;

  /// What can be spent right now (ISO 20022 balance type `ITAV`). The server
  /// owns it. The app only ever displays it.
  final Money availableBalance;

  bool canCover(Money amount) => availableBalance >= amount;

  @override
  List<Object> get props => [id, companyId, name, iban, availableBalance];

  @override
  String toString() => 'Account(id: $id, iban: $iban)';
}
