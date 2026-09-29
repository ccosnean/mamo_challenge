import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/app/routes.dart';
import 'package:payments_app/app/shell/app_shell.dart';
import 'package:payments_app/features/account/presentation/accounts_page.dart';
import 'package:payments_app/features/auth/domain/domain.dart';
import 'package:payments_app/features/auth/presentation/demo_account.dart';
import 'package:payments_app/features/auth/presentation/login_cubit.dart';
import 'package:payments_app/features/auth/presentation/login_page.dart';
import 'package:payments_app/features/auth/presentation/session_cubit.dart';
import 'package:payments_app/features/home/presentation/home_cubit.dart';
import 'package:payments_app/features/home/presentation/home_page.dart';
import 'package:payments_app/features/payments/domain/domain.dart';
import 'package:payments_app/features/payments/presentation/details/payment_details_page.dart';
import 'package:payments_app/features/payments/presentation/payments_page.dart';

final Logger _log = Logger('Router');

/// Login, then three tabs, each keeping its own state, plus payment details
/// on the root navigator: it covers the tab bar, and back returns to
/// whichever tab opened it.
///
/// Signed-out users only ever see login; signing in or out moves between
/// the two automatically.
GoRouter createRouter({
  required GlobalKey<NavigatorState> navigatorKey,
  required SessionCubit session,
  required AuthRepository auth,
  required PaymentsRepository payments,
  required Clock clock,
  DemoAccount? demoAccount,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: _SessionListenable(session),
    redirect: (context, state) {
      final signedIn = session.state != null;
      final atLogin = state.matchedLocation == AppRoutes.login;
      final target = !signedIn
          ? (atLogin ? null : AppRoutes.login)
          : (atLogin ? AppRoutes.home : null);
      if (target != null) {
        _log.fine(
          'Redirect ${state.matchedLocation} → $target '
          '(${signedIn ? 'signed in' : 'signed out'})',
        );
      }
      return target;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => BlocProvider(
          create: (_) => LoginCubit(auth),
          child: LoginPage(demoAccount: demoAccount),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => BlocProvider(
                  create: (_) => HomeCubit(payments, clock: clock),
                  child: const HomePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.payments,
                builder: (_, _) => const PaymentsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.accounts,
                builder: (_, _) => const AccountsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.paymentDetailsPattern,
        parentNavigatorKey: navigatorKey,
        builder: (_, state) => PaymentDetailsPage(
          paymentId: PaymentId(state.pathParameters['id'] ?? ''),
        ),
      ),
    ],
  );
}

/// Re-runs the router's redirect whenever the session changes.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(SessionCubit session) {
    _subscription = session.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
