import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payments_app/core/banking/iban.dart';
import 'package:payments_app/core/device_auth/device_authenticator.dart';
import 'package:payments_app/core/money/currency.dart';
import 'package:payments_app/core/money/money.dart';
import 'package:payments_app/features/account/domain/domain.dart';
import 'package:payments_app/features/approval/presentation/approval_bloc.dart';
import 'package:payments_app/features/approval/presentation/approval_queue_cubit.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

class MockPaymentsRepository extends Mock implements PaymentsRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockDeviceAuthenticator extends Mock implements DeviceAuthenticator {}

final _iban = Iban.parse('AE070331234567890123456');
final _now = DateTime.utc(2026, 9, 28, 12);

PaymentRequest _request(String id) => PaymentRequest(
  id: PaymentId(id),
  reference: 'PAY-$id',
  payee: Party(id: 'p', name: 'Payee', account: _iban),
  amount: const Money.minor(1000, Currency.aed),
  createdAt: _now,
  expiresAt: _now.add(const Duration(hours: 24)),
);

final Account _account = Account(
  id: 'current',
  companyId: 'c',
  name: 'Current',
  iban: _iban,
  availableBalance: const Money.minor(100000, Currency.aed),
);

void main() {
  late MockPaymentsRepository payments;
  late MockAccountRepository accounts;
  late MockDeviceAuthenticator faceId;
  late StreamController<List<PaymentRequest>> pendingStream;

  final a = _request('1');
  final b = _request('2');
  final c = _request('3');

  setUpAll(() => registerFallbackValue(const PaymentId('fallback')));

  setUp(() {
    payments = MockPaymentsRepository();
    accounts = MockAccountRepository();
    faceId = MockDeviceAuthenticator();
    pendingStream = StreamController<List<PaymentRequest>>.broadcast();
    when(
      payments.watchPendingRequests,
    ).thenAnswer((_) => pendingStream.stream);
    when(accounts.watchAccounts).thenAnswer((_) => Stream.value([_account]));
    when(() => payments.reject(any())).thenAnswer((invocation) async {
      final id = invocation.positionalArguments.single as PaymentId;
      final request = [a, b, c].firstWhere((r) => r.id == id);
      return Payment(
        id: request.id,
        reference: request.reference,
        payee: request.payee,
        amount: request.amount,
        requestedAt: request.createdAt,
        status: PaymentStatus.rejected,
        decidedAt: _now,
      );
    });
  });

  tearDown(() => pendingStream.close());

  ApprovalQueueCubit build(List<PaymentRequest> pending, {PaymentId? start}) =>
      ApprovalQueueCubit(
        payments: payments,
        accounts: accounts,
        authenticator: faceId,
        pending: pending,
        initial: start,
      );

  void faceIdAnswers(DeviceAuthResult result) => when(
    () => faceId.authenticate(reason: any(named: 'reason')),
  ).thenAnswer((_) async => result);

  test('one page per pending request, starting on the chosen one', () async {
    final queue = build([a, b, c], start: b.id);

    expect(queue.state.requests, [a, b, c]);
    expect(queue.state.current, b);
    expect(queue.state.lock, QueueLock.locked);
    await queue.close();
  });

  test('pages can be switched, within bounds', () async {
    final queue = build([a, b])
      ..next()
      ..next();
    expect(queue.state.index, 1);

    queue
      ..previous()
      ..previous();
    expect(queue.state.index, 0);
    await queue.close();
  });

  group('unlock', () {
    test('one Face ID reveals every page, and later ones too', () async {
      faceIdAnswers(DeviceAuthResult.success);
      final queue = build([a, b]);
      await queue.unlock();
      await pumpEventQueue();

      expect(queue.state.unlocked, isTrue);
      expect(queue.pageFor(a).state.revealed, isTrue);
      expect(queue.pageFor(b).state.revealed, isTrue);

      pendingStream.add([a, b, c]);
      await pumpEventQueue();
      expect(queue.state.requests, [a, b, c]);
      expect(queue.pageFor(c).state.revealed, isTrue);

      await queue.unlock(); // Already unlocked: no second prompt.
      verify(
        () => faceId.authenticate(reason: any(named: 'reason')),
      ).called(1);
      await queue.close();
    });

    test('a failed Face ID keeps every page masked, with a notice', () async {
      faceIdAnswers(DeviceAuthResult.failed);
      final queue = build([a, b]);
      await queue.unlock();
      await pumpEventQueue();

      expect(queue.state.lock, QueueLock.locked);
      expect(queue.state.unlockNotice, UnlockNotice.failed);
      expect(queue.pageFor(a).state.revealed, isFalse);
      await queue.close();
    });

    test('locking again hides every page', () async {
      faceIdAnswers(DeviceAuthResult.success);
      final queue = build([a, b]);
      await queue.unlock();
      await pumpEventQueue();

      queue.lock();
      await pumpEventQueue();

      expect(queue.state.lock, QueueLock.locked);
      expect(queue.pageFor(a).state.revealed, isFalse);
      expect(queue.pageFor(b).state.revealed, isFalse);
      await queue.close();
    });
  });

  group('decisions', () {
    test('a decided page leaves and the next takes its place', () async {
      final queue = build([a, b, c], start: b.id);

      queue.pageFor(b).add(const ApprovalRejectRequested());
      await pumpEventQueue();

      expect(queue.state.requests, [a, c]);
      expect(queue.state.current, c);
      expect(queue.state.outcomes, [ApprovalOutcome.rejected]);
      expect(queue.state.finished, isFalse);
      await queue.close();
    });

    test('deciding the last page finishes the sheet', () async {
      final queue = build([a]);

      queue.pageFor(a).add(const ApprovalRejectRequested());
      await pumpEventQueue();

      expect(queue.state.finished, isTrue);
      expect(queue.result.anyApproved, isFalse);
      expect(queue.result.count(ApprovalOutcome.rejected), 1);
      await queue.close();
    });

    test('a request that stops being pending leaves as expired', () async {
      final queue = build([a, b]);

      pendingStream.add([b]);
      await pumpEventQueue();

      expect(queue.state.requests, [b]);
      expect(queue.state.outcomes, [ApprovalOutcome.expired]);
      await queue.close();
    });
  });
}
