import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payments_app/core/banking/iban.dart';
import 'package:payments_app/core/money/currency.dart';
import 'package:payments_app/core/money/money.dart';
import 'package:payments_app/features/account/domain/domain.dart';
import 'package:payments_app/features/approval/presentation/approval_bloc.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

class MockPaymentsRepository extends Mock implements PaymentsRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

final _iban = Iban.parse('AE070331234567890123456');
final _now = DateTime.utc(2026, 9, 28, 12);

final _request = PaymentRequest(
  id: const PaymentId('req-1'),
  reference: 'PAY-88213',
  payee: Party(id: 'p', name: 'Ahmed Khalil', account: _iban),
  amount: const Money.minor(120000, Currency.aed),
  createdAt: _now,
  expiresAt: _now.add(const Duration(hours: 24)),
  note: 'Design retainer',
);

Account _account(String id, int fils) => Account(
  id: id,
  companyId: 'c',
  name: id,
  iban: _iban,
  availableBalance: Money.minor(fils, Currency.aed),
);

// Listed poor-first, to check the default skips accounts that can't pay.
final Account _poor = _account('savings', 15000);
final Account _rich = _account('current', 1246025);

Payment _paid(PaymentStatus status) => Payment(
  id: _request.id,
  reference: _request.reference,
  payee: _request.payee,
  amount: _request.amount,
  requestedAt: _request.createdAt,
  status: status,
  decidedAt: _now,
  debtorAccountId: status.isApproved ? _rich.id : null,
);

void main() {
  late MockPaymentsRepository payments;
  late MockAccountRepository accounts;
  late StreamController<List<Account>> accountsStream;

  setUpAll(() => registerFallbackValue(const PaymentId('fallback')));

  setUp(() {
    payments = MockPaymentsRepository();
    accounts = MockAccountRepository();
    accountsStream = StreamController<List<Account>>.broadcast();
    when(accounts.watchAccounts).thenAnswer((_) => accountsStream.stream);
  });

  tearDown(() => accountsStream.close());

  Future<ApprovalBloc> build({bool revealed = false}) async {
    final bloc = ApprovalBloc(
      request: _request,
      payments: payments,
      accounts: accounts,
      revealed: revealed,
    );
    accountsStream.add([_poor, _rich]);
    await pumpEventQueue();
    return bloc;
  }

  void approveAnswers(Future<Payment> Function() answer) => when(
    () => payments.approve(any(), fromAccountId: any(named: 'fromAccountId')),
  ).thenAnswer((_) => answer());

  test('starts masked with the accounts loaded', () async {
    final bloc = await build();

    expect(bloc.state.revealed, isFalse);
    expect(bloc.state.accounts, [_poor, _rich]);
    expect(bloc.state.canApprove, isFalse);
    await bloc.close();
  });

  group('reveal', () {
    test('preselects an account that can pay', () async {
      final bloc = await build()
        ..add(const ApprovalRevealed());
      await pumpEventQueue();

      expect(bloc.state.revealed, isTrue);
      expect(bloc.state.selectedAccountId, _rich.id);
      expect(bloc.state.canApprove, isTrue);
      await bloc.close();
    });

    test('a page that joins an unlocked sheet starts revealed', () async {
      final bloc = await build(revealed: true);

      expect(bloc.state.revealed, isTrue);
      expect(bloc.state.selectedAccountId, _rich.id);
      await bloc.close();
    });

    test('concealing hides the details again, keeping the choice', () async {
      final bloc = await build(revealed: true)
        ..add(const ApprovalConcealed());
      await pumpEventQueue();

      expect(bloc.state.revealed, isFalse);
      expect(bloc.state.canApprove, isFalse);
      expect(bloc.state.selectedAccountId, _rich.id);
      await bloc.close();
    });

    test('approving is impossible while masked', () async {
      final bloc = await build()
        ..add(const ApprovalApproveRequested());
      await pumpEventQueue();

      verifyNever(
        () =>
            payments.approve(any(), fromAccountId: any(named: 'fromAccountId')),
      );
      await bloc.close();
    });
  });

  group('approve', () {
    test('pays from the selected account', () async {
      approveAnswers(() async => _paid(PaymentStatus.completed));
      final bloc = await build(revealed: true)
        ..add(const ApprovalApproveRequested());
      await pumpEventQueue();

      expect(bloc.state.outcome, ApprovalOutcome.approved);
      verify(
        () => payments.approve(_request.id, fromAccountId: _rich.id),
      ).called(1);
      await bloc.close();
    });

    test('an account that cannot cover it disables approve', () async {
      final bloc = await build(revealed: true)
        ..add(ApprovalAccountSelected(_poor.id))
        ..add(const ApprovalApproveRequested());
      await pumpEventQueue();

      expect(bloc.state.selectedCannotCover, isTrue);
      expect(bloc.state.canApprove, isFalse);
      verifyNever(
        () =>
            payments.approve(any(), fromAccountId: any(named: 'fromAccountId')),
      );
      await bloc.close();
    });

    test('a server-side AM04 refusal keeps the page open', () async {
      approveAnswers(() => throw InsufficientFundsException(_request.id));
      final bloc = await build(revealed: true)
        ..add(const ApprovalApproveRequested());
      await pumpEventQueue();

      expect(bloc.state.outcome, isNull);
      expect(bloc.state.notice, ApprovalNotice.insufficientFunds);
      expect(bloc.state.busy, isFalse);
      await bloc.close();
    });

    test('a double tap sends one decision', () async {
      final decision = Completer<Payment>();
      approveAnswers(() => decision.future);
      final bloc = await build(revealed: true)
        ..add(const ApprovalApproveRequested())
        ..add(const ApprovalApproveRequested())
        ..add(const ApprovalRejectRequested());
      await pumpEventQueue();
      decision.complete(_paid(PaymentStatus.completed));
      await pumpEventQueue();

      verify(
        () =>
            payments.approve(any(), fromAccountId: any(named: 'fromAccountId')),
      ).called(1);
      verifyNever(() => payments.reject(any()));
      expect(bloc.state.outcome, ApprovalOutcome.approved);
      await bloc.close();
    });

    test('an outage is retryable', () async {
      approveAnswers(() => throw const PaymentsUnavailableException());
      final bloc = await build(revealed: true)
        ..add(const ApprovalApproveRequested());
      await pumpEventQueue();

      expect(bloc.state.notice, ApprovalNotice.serviceUnavailable);
      expect(bloc.state.canApprove, isTrue);
      await bloc.close();
    });

    test('a 401 ends the page as sessionEnded', () async {
      approveAnswers(() => throw const PaymentsUnauthorizedException());
      final bloc = await build(revealed: true)
        ..add(const ApprovalApproveRequested());
      await pumpEventQueue();

      expect(bloc.state.outcome, ApprovalOutcome.sessionEnded);
      await bloc.close();
    });
  });

  group('reject', () {
    test('works while masked', () async {
      when(
        () => payments.reject(_request.id),
      ).thenAnswer((_) async => _paid(PaymentStatus.rejected));
      final bloc = await build()
        ..add(const ApprovalRejectRequested());
      await pumpEventQueue();

      expect(bloc.state.outcome, ApprovalOutcome.rejected);
      await bloc.close();
    });
  });

  group('leaving without a decision', () {
    test('an expired request ends the page', () async {
      when(
        () => payments.reject(any()),
      ).thenThrow(PaymentRequestExpiredException(_request.id));
      final bloc = await build()
        ..add(const ApprovalRejectRequested());
      await pumpEventQueue();

      expect(bloc.state.outcome, ApprovalOutcome.expired);
      await bloc.close();
    });

    test('a request withdrawn while idle ends the page', () async {
      final bloc = await build()
        ..add(const ApprovalRequestWithdrawn());
      await pumpEventQueue();

      expect(bloc.state.outcome, ApprovalOutcome.expired);
      await bloc.close();
    });

    test('a withdrawal during a decision waits for its result', () async {
      final decision = Completer<Payment>();
      when(() => payments.reject(any())).thenAnswer((_) => decision.future);
      final bloc = await build()
        ..add(const ApprovalRejectRequested())
        ..add(const ApprovalRequestWithdrawn());
      await pumpEventQueue();
      decision.complete(_paid(PaymentStatus.rejected));
      await pumpEventQueue();

      expect(bloc.state.outcome, ApprovalOutcome.rejected);
      await bloc.close();
    });
  });
}
