import 'package:meta/meta.dart';

/// Server-side records. Deliberately independent of the app's models: the
/// app only ever sees the JSON these produce, like with a real bank API.

/// `{"amount": "1200.00", "currency": "AED"}`: amounts travel as decimal
/// strings so no float ever touches money (Open Banking style). Every amount
/// in this bank is in AED fils.
Map<String, Object?> _amountJson(int fils) {
  final sign = fils < 0 ? '-' : '';
  final units = fils.abs().toString().padLeft(3, '0');
  final major = units.substring(0, units.length - 2);
  final minor = units.substring(units.length - 2);
  return {'amount': '$sign$major.$minor', 'currency': 'AED'};
}

String _time(DateTime time) => time.toUtc().toIso8601String();

@immutable
final class ServerParty {
  const ServerParty({required this.id, required this.name, required this.iban});

  final String id;
  final String name;
  final String iban;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'iban': iban};
}

@immutable
final class ServerAccount {
  const ServerAccount({
    required this.id,
    required this.companyId,
    required this.name,
    required this.iban,
    required this.balance,
  });

  final String id;
  final String companyId;
  final String name;
  final String iban;

  /// Available balance in fils.
  final int balance;

  ServerAccount withBalance(int balance) => ServerAccount(
    id: id,
    companyId: companyId,
    name: name,
    iban: iban,
    balance: balance,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'company_id': companyId,
    'name': name,
    'iban': iban,
    'available_balance': _amountJson(balance),
  };
}

@immutable
final class ServerPaymentRequest {
  const ServerPaymentRequest({
    required this.id,
    required this.reference,
    required this.payee,
    required this.amount,
    required this.createdAt,
    required this.expiresAt,
    this.note,
  });

  final String id;
  final String reference;
  final ServerParty payee;

  /// In fils.
  final int amount;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? note;

  Map<String, Object?> toJson() => {
    'id': id,
    'reference': reference,
    'payee': payee.toJson(),
    'amount': _amountJson(amount),
    'note': note,
    'created_at': _time(createdAt),
    'expires_at': _time(expiresAt),
  };
}

@immutable
final class ServerPayment {
  const ServerPayment({
    required this.request,
    required this.status,
    required this.decidedAt,
    this.debtorAccountId,
  });

  final ServerPaymentRequest request;

  /// `completed` or `rejected` (ISO 20022 ACSC / RJCT).
  final String status;
  final DateTime decidedAt;
  final String? debtorAccountId;

  String get id => request.id;

  Map<String, Object?> toJson() => {
    'id': request.id,
    'reference': request.reference,
    'payee': request.payee.toJson(),
    'amount': _amountJson(request.amount),
    'note': request.note,
    'requested_at': _time(request.createdAt),
    'status': status,
    'decided_at': _time(decidedAt),
    'debtor_account_id': debtorAccountId,
  };
}
