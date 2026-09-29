import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mock_bank/mock_bank.dart';
import 'package:payments_app/core/logging/log_sink.dart';
import 'package:payments_app/core/logging/logging.dart';
import 'package:payments_app/core/money/currency.dart';
import 'package:payments_app/core/money/money.dart';
import 'package:payments_app/features/account/data/account_repository_impl.dart';
import 'package:payments_app/features/auth/data/auth_repository_impl.dart';
import 'package:payments_app/features/auth/data/auth_token_interceptor.dart';
import 'package:payments_app/features/auth/domain/domain.dart';
import 'package:payments_app/features/payments/data/payments_repository_impl.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

class _Collect implements LogSink {
  final List<LogEntry> entries = [];

  @override
  void write(LogEntry entry) => entries.add(entry);
}

/// The real repositories and interceptors, over dio and JSON, against the
/// mock bank standing in for the server.
void main() {
  const user = (
    username: 'layla.haddad',
    password: 'correct horse battery staple',
    name: 'Layla Haddad',
    companyName: 'Palmline Studio FZ-LLC',
  );
  const timeout = Timeout(Duration(seconds: 5));

  late MockBankServer server;
  late AuthRepositoryImpl auth;
  late AccountRepositoryImpl accounts;
  late PaymentsRepositoryImpl payments;

  setUp(() {
    server = MockBankServer(
      demoUser: user,
      clock: Clock.fixed(DateTime.utc(2026, 9, 28, 12)),
      latency: Duration.zero,
      seed: 5,
      accounts: const [
        (name: 'Rich', balance: 100000000),
        (name: 'Empty', balance: 0),
      ],
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://bank.test'));
    auth = AuthRepositoryImpl(dio);
    dio.interceptors.addAll([
      AuthTokenInterceptor(auth),
      MockBankInterceptor(server),
    ]);
    accounts = AccountRepositoryImpl(
      dio: dio,
      tokens: auth,
      pollInterval: const Duration(milliseconds: 20),
    );
    payments = PaymentsRepositoryImpl(
      dio: dio,
      tokens: auth,
      accounts: accounts,
      pollInterval: const Duration(milliseconds: 20),
    );
  });

  tearDown(() async {
    await payments.dispose();
    await accounts.dispose();
    await auth.dispose();
    await server.dispose();
  });

  Future<User> signIn() =>
      auth.signIn(username: user.username, password: user.password);

  Future<List<PaymentRequest>> pendingWhere(
    bool Function(List<PaymentRequest>) test,
  ) => payments.watchPendingRequests().firstWhere(test);

  group('auth', () {
    test('starts signed out', () async {
      expect(auth.accessToken, isNull);
      expect(await auth.watchCurrentUser().first, isNull);
    });

    test('signs in with the password grant and loads the user', () async {
      final signedIn = await signIn();

      expect(signedIn.name, user.name);
      expect(signedIn.company.name, user.companyName);
      expect(auth.accessToken, startsWith('at_'));
      expect(await auth.watchCurrentUser().first, signedIn);
    });

    test('wrong credentials stay signed out', () async {
      await expectLater(
        auth.signIn(username: user.username, password: 'wrong'),
        throwsA(isA<InvalidCredentialsException>()),
      );
      expect(auth.accessToken, isNull);
    });

    test('an unreachable server is retryable, not "wrong password"', () async {
      server.offline = true;

      await expectLater(signIn(), throwsA(isA<AuthUnavailableException>()));
    });

    test('signing out revokes the token on the server', () async {
      await signIn();
      expect((await server.watch().first).activeSessions, 1);

      await auth.signOut();

      expect(auth.accessToken, isNull);
      expect((await server.watch().first).activeSessions, 0);
    });
  });

  group('accounts', () {
    test('load on sign-in, parsed exactly', () async {
      await signIn();

      final loaded = await accounts.watchAccounts().firstWhere(
        (list) => list.isNotEmpty,
      );

      expect(loaded.map((a) => a.name), ['Rich', 'Empty']);
      expect(
        loaded.first.availableBalance,
        const Money.minor(100000000, Currency.aed),
      );
      expect(loaded.first.iban.countryCode, 'AE');
    }, timeout: timeout);

    test('polling picks up a server-side top-up', () async {
      await signIn();
      final before = (await accounts.watchAccounts().firstWhere(
        (l) => l.isNotEmpty,
      )).last;

      server.topUp(50000, accountId: before.id);

      final after = await accounts.watchAccounts().firstWhere(
        (l) => l.last.availableBalance != before.availableBalance,
      );
      expect(
        after.last.availableBalance,
        before.availableBalance + const Money.minor(50000, Currency.aed),
      );
    }, timeout: timeout);

    test('are empty while signed out', () async {
      expect(await accounts.watchAccounts().first, isEmpty);
    });
  });

  group('payments', () {
    test('history loads on sign-in, most recent first', () async {
      await signIn();

      final history = await payments.watchPayments().firstWhere(
        (list) => list.isNotEmpty,
      );

      final times = history.map((p) => p.decidedAt).toList();
      expect(times, [...times]..sort((a, b) => b.compareTo(a)));
    }, timeout: timeout);

    test('polling picks up a new request', () async {
      await signIn();
      await pendingWhere((list) => list.isEmpty);

      final sent = server.sendPaymentRequest();

      final pending = await pendingWhere((list) => list.isNotEmpty);
      expect(pending.single.reference, sent.reference);
      expect(pending.single.amount, Money.minor(sent.amount, Currency.aed));
    }, timeout: timeout);

    test(
      'approving shows the payment at once and debits the balance',
      () async {
        await signIn();
        server.sendPaymentRequest();
        final request = (await pendingWhere((l) => l.isNotEmpty)).single;
        final rich = (await accounts.watchAccounts().firstWhere(
          (l) => l.isNotEmpty,
        )).first;

        final payment = await payments.approve(
          request.id,
          fromAccountId: rich.id,
        );

        // Straight from the cache: no waiting for a refresh.
        expect((await payments.watchPayments().first).first, payment);
        expect(await payments.watchPendingRequests().first, isEmpty);
        final debited = await accounts.watchAccounts().firstWhere(
          (l) => l.first.availableBalance != rich.availableBalance,
        );
        expect(
          debited.first.availableBalance,
          rich.availableBalance - request.amount,
        );
      },
      timeout: timeout,
    );

    test('an account without funds is refused, request stays', () async {
      await signIn();
      server.sendPaymentRequest();
      final request = (await pendingWhere((l) => l.isNotEmpty)).single;
      final empty = (await accounts.watchAccounts().firstWhere(
        (l) => l.isNotEmpty,
      )).last;

      await expectLater(
        payments.approve(request.id, fromAccountId: empty.id),
        throwsA(isA<InsufficientFundsException>()),
      );
      expect(await payments.watchPendingRequests().first, [request]);
    }, timeout: timeout);

    test('deciding twice reports the second', () async {
      await signIn();
      server.sendPaymentRequest();
      final request = (await pendingWhere((l) => l.isNotEmpty)).single;

      await payments.reject(request.id);

      await expectLater(
        payments.reject(request.id),
        throwsA(isA<PaymentAlreadyDecidedException>()),
      );
    }, timeout: timeout);

    test(
      'offline keeps the last data and fails actions as retryable',
      () async {
        await signIn();
        final history = await payments.watchPayments().firstWhere(
          (l) => l.isNotEmpty,
        );
        server.sendPaymentRequest();
        final request = (await pendingWhere((l) => l.isNotEmpty)).single;

        server.offline = true;
        await payments.refresh();

        expect(await payments.watchPayments().first, history);
        await expectLater(
          payments.reject(request.id),
          throwsA(isA<PaymentsUnavailableException>()),
        );
      },
      timeout: timeout,
    );
  });

  group('session', () {
    test('a 401 ends the session and clears cached data', () async {
      await signIn();
      await payments.watchPayments().firstWhere((l) => l.isNotEmpty);

      server.revokeAllTokens();

      await expectLater(
        payments.refresh().then((_) => payments.reject(const PaymentId('x'))),
        throwsA(isA<PaymentsUnauthorizedException>()),
      );
      expect(auth.accessToken, isNull);
      expect(await payments.watchPayments().first, isEmpty);
      expect(await accounts.watchAccounts().first, isEmpty);
    }, timeout: timeout);

    test('data from a previous session never shows in the next', () async {
      await signIn();
      await auth.signOut();

      expect(await payments.watchPayments().first, isEmpty);
      expect(await payments.watchPendingRequests().first, isEmpty);
    });
  });

  test('with masking on, logs never show tokens, IBANs or amounts', () async {
    final sink = _Collect();
    configureLogging(level: Level.ALL, sinks: [sink], redact: true);
    addTearDown(() => configureLogging(level: Level.OFF, sinks: const []));

    await signIn();
    final token = auth.accessToken!;
    server.sendPaymentRequest();
    final request = (await pendingWhere((l) => l.isNotEmpty)).single;
    final rich = (await accounts.watchAccounts().firstWhere(
      (l) => l.isNotEmpty,
    )).first;
    await payments.approve(request.id, fromAccountId: rich.id);
    await pumpEventQueue();

    final output = sink.entries
        .map((e) => '${e.message} ${e.error ?? ''}')
        .join('\n');
    expect(output, contains(request.reference), reason: 'still useful');
    expect(output, contains('at_•••'), reason: 'token was logged, masked');
    expect(output, contains('AED •••'), reason: 'amounts were logged, masked');
    expect(output, isNot(contains(token)));
    expect(output, isNot(contains(rich.iban.value)));
    expect(output, isNot(contains(request.payee.account.value)));
    expect(output, isNot(contains(request.payee.name)));
    expect(output, isNot(contains(user.name)));
  }, timeout: timeout);
}
