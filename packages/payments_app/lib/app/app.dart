import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/app/router.dart';
import 'package:payments_app/core/device_auth/device_authenticator.dart';
import 'package:payments_app/core/ui/theme/app_theme.dart';
import 'package:payments_app/features/account/domain/domain.dart';
import 'package:payments_app/features/account/presentation/accounts_cubit.dart';
import 'package:payments_app/features/approval/presentation/approval_coordinator.dart';
import 'package:payments_app/features/auth/domain/domain.dart';
import 'package:payments_app/features/auth/presentation/demo_account.dart';
import 'package:payments_app/features/auth/presentation/session_cubit.dart';
import 'package:payments_app/features/payments/domain/domain.dart';
import 'package:payments_app/features/payments/presentation/payments_cubits.dart';

/// The app, given its dependencies (see `configureDependencies`).
///
/// App-wide state lives above the router so every screen and the approval
/// sheet read the same live data.
class App extends StatefulWidget {
  const App({
    required this.auth,
    required this.accounts,
    required this.payments,
    required this.deviceAuthenticator,
    this.demoAccount,
    this.clock = const Clock(),
    super.key,
  });

  final AuthRepository auth;
  final AccountRepository accounts;
  final PaymentsRepository payments;
  final DeviceAuthenticator deviceAuthenticator;
  final DemoAccount? demoAccount;
  final Clock clock;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey(
    debugLabel: 'root',
  );
  // Created here rather than by a provider: the router's sign-in guard
  // needs it before the widget tree exists.
  late final SessionCubit _session = SessionCubit(widget.auth);
  late final GoRouter _router = createRouter(
    navigatorKey: _rootNavigatorKey,
    session: _session,
    auth: widget.auth,
    payments: widget.payments,
    clock: widget.clock,
    demoAccount: widget.demoAccount,
  );

  static final Logger _log = Logger('App');
  static final Logger _navLog = Logger('Navigation');

  late final AppLifecycleListener _lifecycle;
  String? _location;

  @override
  void initState() {
    super.initState();
    _router.routerDelegate.addListener(_onRouteChanged);
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) => _log.fine('Lifecycle: ${state.name}'),
      onResume: _onResume,
    );
  }

  void _onRouteChanged() {
    final location = _router.routerDelegate.currentConfiguration.uri.toString();
    if (location == _location) return;
    _navLog.info('→ $location');
    _location = location;
  }

  /// Back in the foreground: re-read what may have changed meanwhile rather
  /// than wait for the next poll.
  void _onResume() {
    if (_session.state == null) return;
    _log.info('Resumed: refreshing payments and balances');
    unawaited(widget.payments.refresh());
    unawaited(widget.accounts.refresh());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _router.routerDelegate.removeListener(_onRouteChanged);
    _router.dispose();
    unawaited(_session.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _session),
        // App-wide data is subscribed up front, so every screen opens warm.
        BlocProvider(
          lazy: false,
          create: (_) => AccountsCubit(widget.accounts),
        ),
        BlocProvider(create: (_) => BalanceVisibilityCubit()),
        BlocProvider(
          lazy: false,
          create: (_) => PaymentHistoryCubit(widget.payments),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => PendingRequestsCubit(widget.payments),
        ),
      ],
      child: MaterialApp.router(
        title: 'Payments',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
        // The approval sheet opens over whatever screen is showing.
        builder: (context, child) => ApprovalCoordinator(
          navigatorKey: _rootNavigatorKey,
          router: _router,
          payments: widget.payments,
          accounts: widget.accounts,
          authenticator: widget.deviceAuthenticator,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
