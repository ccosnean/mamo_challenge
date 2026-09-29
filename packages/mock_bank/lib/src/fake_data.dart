import 'package:faker/faker.dart' show Faker, RandomGenerator;
import 'package:mock_bank/src/models.dart';

/// Realistic-looking seed data: accounts, payment history and incoming
/// Request-to-Pay requests.
///
/// Draws from a recurring set of payees (people pay the same contacts
/// repeatedly), mixes individuals and UAE businesses with valid UAE IBANs,
/// uses unique `PAY-#####` references, and spreads amounts across everyday,
/// mid-size and large payments. Pass a `seed` for deterministic output.
final class FakeData {
  FakeData({int? seed}) : _faker = Faker(seed: seed);

  final Faker _faker;
  final Set<String> _usedReferences = {};

  late final List<ServerParty> _regularPayees = List.generate(
    8,
    (_) => _newPayee(),
  );

  RandomGenerator get _random => _faker.randomGenerator;

  static const _businessSuffixes = [
    'Trading LLC', 'Studio', 'Consulting FZ-LLC', 'Design Co.', //
    'Technologies FZE', 'Events LLC', 'Interiors',
  ];

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', //
    'August', 'September', 'October', 'November', 'December',
  ];

  String id(String prefix) => '${prefix}_${_faker.guid.guid()}';

  ServerAccount account({
    required String companyId,
    required String name,
    required int balance,
  }) => ServerAccount(
    id: id('acc'),
    companyId: companyId,
    name: name,
    iban: uaeIban(),
    balance: balance,
  );

  /// A new request sent at [createdAt], payable for [validFor].
  ServerPaymentRequest request({
    required DateTime createdAt,
    Duration validFor = const Duration(hours: 24),
  }) => ServerPaymentRequest(
    id: id('pr'),
    reference: _uniqueReference(),
    payee: _payee(),
    amount: _amount(),
    createdAt: createdAt.toUtc(),
    expiresAt: createdAt.add(validFor).toUtc(),
    note: _note(createdAt),
  );

  /// Past decisions, most recent first. Half fall in the current month so a
  /// monthly summary has data on first launch; about one in five is
  /// rejected; the rest are completed, paid from one of [payFrom].
  List<ServerPayment> history({
    required DateTime now,
    required List<String> payFrom,
    int count = 12,
  }) {
    final monthStart = DateTime(now.year, now.month);
    final olderStart = monthStart.subtract(const Duration(days: 60));

    return List.generate(count, (i) {
      final decidedAt = i.isEven
          ? _between(monthStart, now)
          : _between(olderStart, monthStart);
      final createdAt = decidedAt.subtract(
        Duration(minutes: _random.integer(180, min: 1)),
      );
      final rejected = _random.integer(5) == 0;
      return ServerPayment(
        request: request(createdAt: createdAt),
        status: rejected ? 'rejected' : 'completed',
        decidedAt: decidedAt.toUtc(),
        debtorAccountId: rejected ? null : _random.element(payFrom),
      );
    })..sort((a, b) => b.decidedAt.compareTo(a.decidedAt));
  }

  ServerParty _payee() =>
      _random.integer(4) == 0 ? _newPayee() : _random.element(_regularPayees);

  /// Roughly one payee in four is a business.
  ServerParty _newPayee() => ServerParty(
    id: id('pty'),
    name: _random.integer(4) == 0
        ? '${_faker.person.lastName()} ${_random.element(_businessSuffixes)}'
        : '${_faker.person.firstName()} ${_faker.person.lastName()}',
    iban: uaeIban(),
  );

  /// A valid UAE IBAN: `AE` + check digits + 3-digit bank + 16-digit account.
  String uaeIban() {
    final bban = '${_random.numberOfLength(3)}${_random.numberOfLength(16)}';
    final check = (98 - _mod97('${bban}AE00')).toString().padLeft(2, '0');
    return 'AE$check$bban';
  }

  /// Everyday amounts carry fils; larger ones are rounded like invoices.
  int _amount() => switch (_random.integer(10)) {
    < 5 => _random.integer(50000, min: 1500), // 15.00 – 499.99
    < 9 => _random.integer(500, min: 50) * 1000, // 500 – 4,990, tens
    _ => _random.integer(250, min: 50) * 10000, // 5,000 – 24,900, hundreds
  };

  String? _note(DateTime at) {
    final month = _months[at.toLocal().month - 1];
    final notes = <String Function()>[
      () => 'Design retainer',
      () => 'Invoice #${_random.integer(9999, min: 1000)}',
      () => 'Consulting · ${_faker.company.name()}',
      () => 'Office rent · $month',
      () => 'Website maintenance · $month',
      () => 'Team lunch',
      () => 'Freelance copywriting',
      () => 'Equipment reimbursement',
      () => 'Photography deposit',
      () => 'Split: dinner',
    ];
    if (_random.integer(8) == 0) return null;
    return _random.element(notes)();
  }

  String _uniqueReference() {
    while (true) {
      final reference = 'PAY-${_random.integer(100000, min: 10000)}';
      if (_usedReferences.add(reference)) return reference;
    }
  }

  DateTime _between(DateTime start, DateTime end) {
    final seconds = end.difference(start).inSeconds;
    if (seconds <= 0) return start;
    return start.add(Duration(seconds: _random.integer(seconds)));
  }

  static int _mod97(String input) {
    var remainder = 0;
    for (final unit in input.codeUnits) {
      final digits = unit >= 65
          ? (unit - 55).toString()
          : String.fromCharCode(unit);
      for (final digit in digits.codeUnits) {
        remainder = (remainder * 10 + (digit - 48)) % 97;
      }
    }
    return remainder;
  }
}
