import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:mock_bank/src/fake_data.dart';
import 'package:mock_bank/src/latest.dart';
import 'package:mock_bank/src/models.dart';
import 'package:mock_bank/src/oauth.dart';

/// An account to seed the bank with. `balance` is in minor units (fils).
typedef SeedAccount = ({String name, int balance});

@immutable
final class MockHttpRequest {
  const MockHttpRequest({
    required this.method,
    required this.path,
    this.headers = const {},
    this.body,
  });

  final String method;
  final String path;

  /// Lower-case header names.
  final Map<String, String> headers;

  /// Raw JSON, if any.
  final String? body;
}

@immutable
final class MockHttpResponse {
  const MockHttpResponse(this.status, this.body);

  final int status;

  /// Raw JSON.
  final String body;

  bool get ok => status >= 200 && status < 300;
}

/// What the showcase's Bank panel shows: the server's view of the world.
@immutable
final class BankSnapshot {
  const BankSnapshot({
    required this.accounts,
    required this.pendingCount,
    required this.paymentsCount,
    required this.activeSessions,
    required this.latency,
    required this.offline,
  });

  final List<ServerAccount> accounts;
  final int pendingCount;
  final int paymentsCount;
  final int activeSessions;
  final Duration latency;
  final bool offline;
}

/// A small in-memory bank that speaks JSON, like the real API would.
///
/// OAuth 2 password grant at `POST /oauth/token`, revocation at
/// `POST /oauth/revoke`, and bearer-protected resources:
///
/// | Method | Path | |
/// |---|---|---|
/// | GET | `/me` | the token's user and company |
/// | GET | `/accounts` | accounts and available balances |
/// | GET | `/payment-requests` | pending Request-to-Pay requests |
/// | GET | `/payments` | decided payments, most recent first |
/// | POST | `/payment-requests/{id}/approve` | `{"debtor_account_id"}` |
/// | POST | `/payment-requests/{id}/reject` | |
///
/// Errors are `{"error": code, "message": …}` with 400, 401, 404, 409 (already
/// decided), 410 (expired), 422 (insufficient funds, `AM04`).
///
/// Also exposes controls for the showcase: send a request, top up, change
/// latency, go offline, revoke sessions, reset.
///
/// Logs never contain names, IBANs, amounts, notes, passwords or tokens.
final class MockBankServer {
  MockBankServer({
    required DemoUser demoUser,
    Clock clock = const Clock(),
    Duration latency = const Duration(milliseconds: 400),
    Duration requestValidity = const Duration(hours: 24),
    Duration tokenLifetime = const Duration(hours: 1),
    List<SeedAccount> accounts = defaultAccounts,
    int? seed,
    Random? random,
  }) : assert(accounts.isNotEmpty, 'At least one account is needed'),
       _demoUser = demoUser,
       _clock = clock,
       _latency = latency,
       _requestValidity = requestValidity,
       _tokenLifetime = tokenLifetime,
       _seedAccounts = accounts,
       _seed = seed,
       _random = random ?? Random.secure() {
    _reseed();
  }

  /// Three AED accounts. Savings is nearly empty, to showcase insufficient
  /// funds.
  static const List<SeedAccount> defaultAccounts = [
    (name: 'Current account', balance: 1246025),
    (name: 'Business', balance: 585000),
    (name: 'Savings', balance: 15000),
  ];

  static final Logger _log = Logger('MockBank');

  final DemoUser _demoUser;
  final Clock _clock;
  final Duration _requestValidity;
  final Duration _tokenLifetime;
  final List<SeedAccount> _seedAccounts;
  final int? _seed;
  final Random _random;

  Duration _latency;
  bool _offline = false;

  late FakeData _data;
  late String _userId;
  late String _companyId;
  late StoredCredential _credential;
  final Map<String, ({String userId, DateTime expiresAt})> _tokens = {};
  late List<ServerAccount> _accounts;
  late List<ServerPayment> _payments;
  List<ServerPaymentRequest> _pending = const [];
  final Map<String, Timer> _expiryTimers = {};
  final Set<String> _expired = {};

  late final Latest<BankSnapshot> _snapshot = Latest(_takeSnapshot());

  /// Simulated network round trip, applied to every request.
  Duration get latency => _latency;

  set latency(Duration value) {
    _latency = value;
    _log.info('Latency set to ${value.inMilliseconds} ms');
    _publish();
  }

  /// While offline, requests fail as if the network were down.
  bool get offline => _offline;

  set offline(bool value) {
    _offline = value;
    _log.info(value ? 'Bank offline' : 'Bank online');
    _publish();
  }

  /// A payee sends the user a new Request-to-Pay.
  ServerPaymentRequest sendPaymentRequest() {
    final request = _data.request(
      createdAt: _clock.now(),
      validFor: _requestValidity,
    );
    _pending = List.unmodifiable([..._pending, request]);
    _expiryTimers[request.id] = Timer(
      request.expiresAt.difference(_clock.now()),
      () => _expire(request.id),
    );
    _log.info(
      '${request.reference} received (${_pending.length} pending)',
    );
    _publish();
    return request;
  }

  /// Credits [amount] fils to [accountId], or to the account with the lowest
  /// balance.
  void topUp(int amount, {String? accountId}) {
    final target = accountId == null
        ? _accounts.reduce((a, b) => a.balance <= b.balance ? a : b)
        : _accounts.where((a) => a.id == accountId).firstOrNull;
    if (target == null) return;
    _replaceAccount(target.withBalance(target.balance + amount));
    _log.info('Account ${target.id} topped up');
    _publish();
  }

  /// Ends every session: the app's next call gets a 401.
  void revokeAllTokens() {
    final count = _tokens.length;
    _tokens.clear();
    _log.info('Revoked $count session(s)');
    _publish();
  }

  /// Fresh data and no sessions, as if the bank had just been provisioned.
  void reset() {
    _clearTimers();
    _tokens.clear();
    _reseed();
    _log.info('Bank reset');
    _publish();
  }

  Stream<BankSnapshot> watch() => _snapshot.stream;

  /// The current state, synchronously.
  BankSnapshot get snapshot => _takeSnapshot();

  Future<void> dispose() async {
    _clearTimers();
    await _snapshot.close();
  }

  /// Handles one JSON request after the simulated [latency].
  Future<MockHttpResponse> handle(MockHttpRequest request) async {
    final watch = Stopwatch()..start();
    await Future<void>.delayed(_latency);
    final response = _route(request);
    _log.fine(
      '${request.method} ${request.path} → ${response.status} '
      '(${watch.elapsedMilliseconds} ms)',
    );
    return response;
  }

  MockHttpResponse _route(MockHttpRequest request) {
    final segments = Uri.parse(request.path).pathSegments;
    final route = '${request.method} /${segments.join('/')}';

    if (route == 'POST /oauth/token') return _token(request);
    if (route == 'POST /oauth/revoke') return _revoke(request);

    final userId = _authorize(request);
    if (userId == null) {
      return _error(401, 'invalid_token', 'Missing, expired or revoked token');
    }

    return switch ((request.method, segments)) {
      ('GET', ['me']) => _json(200, _me()),
      ('GET', ['accounts']) => _json(200, {
        'data': [for (final a in _accounts) a.toJson()],
      }),
      ('GET', ['payment-requests']) => _json(200, {
        'data': [for (final r in _pending) r.toJson()],
      }),
      ('GET', ['payments']) => _json(200, {
        'data': [for (final p in _payments) p.toJson()],
      }),
      ('POST', ['payment-requests', final id, 'approve']) => _decide(
        id,
        debtorAccountId: _field(request, 'debtor_account_id'),
        approve: true,
      ),
      ('POST', ['payment-requests', final id, 'reject']) => _decide(
        id,
        approve: false,
      ),
      _ => _error(404, 'not_found', 'No such endpoint'),
    };
  }

  MockHttpResponse _token(MockHttpRequest request) {
    if (_field(request, 'grant_type') != 'password') {
      return _error(400, 'unsupported_grant_type', 'Use the password grant');
    }
    final username = _field(request, 'username')?.trim().toLowerCase();
    final password = _field(request, 'password') ?? '';
    if (username != _demoUser.username.toLowerCase() ||
        !_credential.matches(password)) {
      _log.warning('Token refused: invalid credentials');
      return _error(400, 'invalid_grant', 'Invalid username or password');
    }
    final token = 'at_${randomUrlSafe(32, _random)}';
    _tokens[token] = (
      userId: _userId,
      expiresAt: _clock.now().add(_tokenLifetime),
    );
    _log.info('Token issued to $_userId');
    _publish();
    return _json(200, {
      'access_token': token,
      'token_type': 'Bearer',
      'expires_in': _tokenLifetime.inSeconds,
    });
  }

  MockHttpResponse _revoke(MockHttpRequest request) {
    final token = _field(request, 'token');
    if (token != null && _tokens.remove(token) != null) {
      _log.info('Token revoked for $_userId');
      _publish();
    }
    // RFC 7009: revoking an unknown token still succeeds.
    return _json(200, const <String, Object?>{});
  }

  /// The user id behind the request's bearer token, or null.
  String? _authorize(MockHttpRequest request) {
    final header = request.headers['authorization'] ?? '';
    if (!header.startsWith('Bearer ')) return null;
    final token = header.substring('Bearer '.length);
    final issued = _tokens[token];
    if (issued == null) return null;
    if (!_clock.now().isBefore(issued.expiresAt)) {
      _tokens.remove(token);
      _log.warning('401: expired token for ${issued.userId}');
      _publish();
      return null;
    }
    return issued.userId;
  }

  Map<String, Object?> _me() => {
    'id': _userId,
    'username': _demoUser.username,
    'name': _demoUser.name,
    'company': {'id': _companyId, 'name': _demoUser.companyName},
  };

  MockHttpResponse _decide(
    String id, {
    required bool approve,
    String? debtorAccountId,
  }) {
    final action = approve ? 'Approve' : 'Reject';
    final request = _pending.where((r) => r.id == id).firstOrNull;
    if (request == null) {
      if (_expired.contains(id)) {
        return _error(410, 'request_expired', 'The request has expired');
      }
      if (_payments.any((p) => p.id == id)) {
        _log.warning('$action refused: already decided');
        return _error(409, 'already_decided', 'Already approved or rejected');
      }
      return _error(404, 'not_found', 'No such payment request');
    }

    final now = _clock.now();
    if (!now.isBefore(request.expiresAt)) {
      _expire(id);
      return _error(410, 'request_expired', 'The request has expired');
    }

    ServerAccount? account;
    if (approve) {
      account = _accounts.where((a) => a.id == debtorAccountId).firstOrNull;
      if (account == null) {
        return _error(400, 'invalid_account', 'Unknown debtor account');
      }
      if (account.balance < request.amount) {
        _log.warning(
          '${request.reference} refused: insufficient funds (AM04)',
        );
        return _error(
          422,
          'insufficient_funds',
          'The account cannot cover the amount',
          extra: {'reason_code': 'AM04'},
        );
      }
    }

    // Debit and record together, as one transaction.
    final payment = ServerPayment(
      request: request,
      status: approve ? 'completed' : 'rejected',
      decidedAt: now.toUtc(),
      debtorAccountId: account?.id,
    );
    if (account != null) {
      _replaceAccount(account.withBalance(account.balance - request.amount));
    }
    _removePending(id);
    _payments = List.unmodifiable(
      <ServerPayment>[payment, ..._payments]
        ..sort((a, b) => b.decidedAt.compareTo(a.decidedAt)),
    );
    _log.info(
      '${request.reference} ${approve ? 'approved' : 'rejected'} '
      '(${_pending.length} pending)',
    );
    _publish();
    return _json(200, payment.toJson());
  }

  void _reseed() {
    _data = FakeData(seed: _seed);
    _userId = _data.id('usr');
    _companyId = _data.id('co');
    _credential = StoredCredential.create(
      password: _demoUser.password,
      random: _random,
    );
    _accounts = List.unmodifiable([
      for (final seed in _seedAccounts)
        _data.account(
          companyId: _companyId,
          name: seed.name,
          balance: seed.balance,
        ),
    ]);
    _payments = List.unmodifiable(
      _data.history(
        now: _clock.now(),
        payFrom: [for (final a in _accounts) a.id],
      ),
    );
    _pending = const [];
    _expired.clear();
  }

  void _expire(String id) {
    _expired.add(id);
    _removePending(id);
    _log.info('Request $id expired');
    _publish();
  }

  void _removePending(String id) {
    _expiryTimers.remove(id)?.cancel();
    _pending = List.unmodifiable(_pending.where((r) => r.id != id));
  }

  void _replaceAccount(ServerAccount updated) {
    _accounts = List.unmodifiable([
      for (final a in _accounts)
        if (a.id == updated.id) updated else a,
    ]);
  }

  void _clearTimers() {
    for (final timer in _expiryTimers.values) {
      timer.cancel();
    }
    _expiryTimers.clear();
  }

  BankSnapshot _takeSnapshot() => BankSnapshot(
    accounts: _accounts,
    pendingCount: _pending.length,
    paymentsCount: _payments.length,
    activeSessions: _tokens.length,
    latency: _latency,
    offline: _offline,
  );

  void _publish() => _snapshot.value = _takeSnapshot();

  static String? _field(MockHttpRequest request, String name) {
    final body = request.body;
    if (body == null || body.isEmpty) return null;
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) return null;
    final value = decoded[name];
    return value is String ? value : null;
  }

  static MockHttpResponse _json(int status, Map<String, Object?> body) =>
      MockHttpResponse(status, jsonEncode(body));

  static MockHttpResponse _error(
    int status,
    String code,
    String message, {
    Map<String, Object?> extra = const {},
  }) => _json(status, {'error': code, 'message': message, ...extra});
}
