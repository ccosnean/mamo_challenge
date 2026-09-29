import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_bank/mock_bank.dart';
import 'package:payments_app/app/di.dart';
import 'package:payments_app/core/ui/widgets/app_button.dart';
import 'package:payments_app/features/payments/domain/domain.dart';
import 'package:payments_app/features/payments/presentation/payments_cubits.dart';
import 'package:payments_app/payments_app.dart';

/// Face ID with a scripted answer.
class _StubAuthenticator implements DeviceAuthenticator {
  DeviceAuthResult result = DeviceAuthResult.success;
  int calls = 0;

  @override
  Future<DeviceAuthResult> authenticate({required String reason}) async {
    calls++;
    return result;
  }
}

/// Settles animations, failing fast instead of hanging if something never
/// stops animating.
Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 5),
);

/// Awaits [future] from a widget test, pumping fake time until it's done:
/// in the fake-async zone nothing progresses between pumps.
Future<T> pumpUntilDone<T>(WidgetTester tester, Future<T> future) async {
  final completer = Completer<T>();
  future.then(completer.complete, onError: completer.completeError).ignore();
  for (var i = 0; i < 200 && !completer.isCompleted; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  if (!completer.isCompleted) fail('Future did not complete');
  return completer.future;
}

/// The whole app, booted the way a host boots it, against the mock bank
/// over dio and JSON. Driven like a user would.
void main() {
  const demo = DemoAccount(
    username: 'layla.haddad',
    password: 'correct horse battery staple',
    name: 'Layla Haddad',
    companyName: 'Palmline Studio FZ-LLC',
    role: 'Finance manager',
  );

  const poll = Duration(seconds: 1);

  late MockBankServer server;
  late _StubAuthenticator faceId;

  var shutDownDone = false;

  Future<void> shutDown(WidgetTester tester) async {
    if (shutDownDone) return;
    shutDownDone = true;
    await tester.pumpWidget(const SizedBox.shrink());
    // Teardown runs on the real event loop: closing streams there needs no
    // fake time. Timers created in the fake zone are still cancelled.
    await tester.runAsync(getIt.reset);
    await tester.runAsync(server.dispose);
  }

  Future<void> launch(
    WidgetTester tester, {
    List<SeedAccount> accounts = MockBankServer.defaultAccounts,
  }) async {
    shutDownDone = false;
    // Safety net if a test fails before its own shutDown.
    addTearDown(() => shutDown(tester));
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    faceId = _StubAuthenticator();
    server = MockBankServer(
      demoUser: (
        username: demo.username,
        password: demo.password,
        name: demo.name,
        companyName: demo.companyName,
      ),
      latency: Duration.zero,
      accounts: accounts,
      seed: 3,
    );
    // Created in the test's fake-async zone, like everything the app does
    // afterwards, so pumping drives all of it.
    await pumpUntilDone(
      tester,
      configureDependencies(
        AppConfig(
          apiBaseUrl: 'https://bank.test',
          deviceAuthenticator: faceId,
          transportInterceptors: [MockBankInterceptor(server)],
          demoAccount: demo,
          pollInterval: poll,
        ),
      ),
    );

    await tester.pumpWidget(const PaymentsApp());
    await settle(tester);

    // Signed out, the app opens on the login screen.
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    await settle(tester);
    expect(find.text('Recent'), findsOneWidget);
  }

  /// The bank sends a request; the app picks it up on its next poll.
  Future<void> sendRequest(WidgetTester tester) async {
    server.sendPaymentRequest();
    await tester.pump(poll);
    await settle(tester);
  }

  Future<void> incomingRequest(WidgetTester tester) async {
    await sendRequest(tester);
    expect(find.text('Approve this payment?'), findsOneWidget);
  }

  /// What the app currently shows as history.
  List<Payment> history(WidgetTester tester) => tester
      .element(find.byType(Navigator).first)
      .read<PaymentHistoryCubit>()
      .state
      .payments;

  testWidgets('a request appears masked over the current screen', (
    tester,
  ) async {
    await launch(tester);
    await incomingRequest(tester);

    expect(find.textContaining('PAY-'), findsWidgets);
    expect(find.text('Review with Face ID'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget, reason: 'still on Home');

    await shutDown(tester);
  });

  testWidgets('approving reveals, pays and lands on Payments', (tester) async {
    // An account that can always cover it: request amounts are random.
    await launch(
      tester,
      accounts: const [(name: 'Current account', balance: 10000000)],
    );
    await incomingRequest(tester);

    await tester.tap(find.text('Review with Face ID'));
    await settle(tester);
    expect(find.text('Pay from'), findsOneWidget);

    final approve = find.widgetWithText(AppButton, 'Approve');
    expect(tester.widget<AppButton>(approve).onPressed, isNotNull);
    await tester.tap(approve);
    await settle(tester);

    expect(find.text('Pay from'), findsNothing, reason: 'sheet closed');
    expect(find.text('Waiting for you'), findsNothing);
    final payment = history(tester).first;
    expect(payment.status, PaymentStatus.completed);
    expect(find.text(payment.payee.name), findsWidgets, reason: 'on top');

    await shutDown(tester);
  });

  testWidgets('rejecting needs no Face ID and stays where the user was', (
    tester,
  ) async {
    await launch(tester);
    await incomingRequest(tester);
    faceId.result = DeviceAuthResult.failed; // Would fail if it were asked.

    await tester.tap(find.text('Reject'));
    await settle(tester);

    expect(find.text('Approve this payment?'), findsNothing);
    expect(find.text('Recent'), findsOneWidget, reason: 'still on Home');
    expect(history(tester).first.status, PaymentStatus.rejected);

    await shutDown(tester);
  });

  testWidgets('a failed Face ID keeps the details hidden', (tester) async {
    await launch(tester);
    await incomingRequest(tester);
    faceId.result = DeviceAuthResult.failed;

    await tester.tap(find.text('Review with Face ID'));
    await settle(tester);

    expect(find.textContaining('didn’t recognise you'), findsOneWidget);
    expect(find.text('Try Face ID again'), findsOneWidget);
    expect(find.text('Pay from'), findsNothing);

    await shutDown(tester);
  });

  testWidgets('an account without funds cannot approve', (tester) async {
    await launch(tester, accounts: const [(name: 'Empty', balance: 0)]);
    await incomingRequest(tester);

    await tester.tap(find.text('Review with Face ID'));
    await settle(tester);

    expect(find.textContaining('Not enough funds in Empty'), findsOneWidget);
    final approve = find.widgetWithText(AppButton, 'Approve');
    expect(tester.widget<AppButton>(approve).onPressed, isNull);

    await shutDown(tester);
  });

  testWidgets('a dismissed request waits on the Payments tab', (tester) async {
    await launch(tester);
    await incomingRequest(tester);

    await tester.tapAt(const Offset(195, 60)); // The scrim above the sheet.
    await settle(tester);
    expect(find.text('Approve this payment?'), findsNothing);

    await tester.tap(find.text('Payments').last);
    await settle(tester);

    expect(find.text('Waiting for you'), findsOneWidget);
    expect(find.textContaining('PAY-'), findsWidgets);

    await shutDown(tester);
  });

  testWidgets('signing out revokes the token and returns to login', (
    tester,
  ) async {
    await launch(tester);

    await tester.tap(find.text(demo.name));
    await settle(tester);
    await tester.tap(find.text('Sign out'));
    await settle(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(server.snapshot.activeSessions, 0);

    await shutDown(tester);
  });

  testWidgets('several requests share one sheet and one Face ID', (
    tester,
  ) async {
    await launch(
      tester,
      accounts: const [(name: 'Current account', balance: 100000000)],
    );
    await incomingRequest(tester);
    expect(find.textContaining('of 2'), findsNothing, reason: 'just one');

    // A second request while the sheet is open joins it as a page.
    await sendRequest(tester);
    expect(find.text('Request 1 of 2'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);

    await tester.tap(find.text('Review with Face ID'));
    await settle(tester);
    expect(find.text('Pay from'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Next request'));
    await settle(tester);
    expect(find.text('Request 2 of 2'), findsOneWidget);
    expect(find.text('Pay from'), findsOneWidget, reason: 'still revealed');
    expect(faceId.calls, 1);

    await tester.tap(find.widgetWithText(AppButton, 'Approve'));
    await settle(tester);
    expect(find.text('Request 2 of 2'), findsNothing, reason: 'one left');
    expect(find.byType(BottomSheet), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Reject'));
    await settle(tester);

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Waiting for you'), findsNothing);
    expect(
      history(tester).take(2).map((p) => p.status),
      containsAll([PaymentStatus.completed, PaymentStatus.rejected]),
    );
    expect(faceId.calls, 1);

    await shutDown(tester);
  });
}
