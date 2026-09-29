/// The payments app, as a host embeds it: configure once, then show
/// [PaymentsApp] anywhere (full screen, or inside a device frame).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/app/app.dart';
import 'package:payments_app/app/app_config.dart';
import 'package:payments_app/app/di.dart';
import 'package:payments_app/core/logging/app_bloc_observer.dart';
import 'package:payments_app/core/logging/console_log_sink.dart';
import 'package:payments_app/core/logging/error_logging.dart';
import 'package:payments_app/core/logging/logging.dart';
import 'package:payments_app/features/account/domain/domain.dart';
import 'package:payments_app/features/auth/domain/domain.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

export 'app/app_config.dart';
export 'core/device_auth/device_authenticator.dart';
export 'core/device_auth/local_auth_device_authenticator.dart';
export 'core/logging/log_sink.dart';
export 'features/auth/presentation/demo_account.dart';

/// Sets up logging and dependencies from [config]. Call before showing
/// [PaymentsApp]; calling again replaces the previous setup.
Future<void> configurePaymentsApp(AppConfig config) async {
  configureLogging(
    level: config.logLevel,
    sinks: [ConsoleLogSink(), ...config.logSinks],
    redact: config.redactLogs,
  );
  installErrorLogging();
  Bloc.observer = AppBlocObserver();
  await configureDependencies(config);
  Logger('PaymentsApp').info(
    'Configured: API ${config.apiBaseUrl}, '
    'poll ${config.pollInterval.inSeconds} s, '
    'logs ${config.redactLogs ? 'masked' : 'unmasked'}',
  );
}

/// The app, wired from the last [configurePaymentsApp] call.
class PaymentsApp extends StatelessWidget {
  const PaymentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = getIt<AppConfig>();
    return App(
      auth: getIt<AuthRepository>(),
      accounts: getIt<AccountRepository>(),
      payments: getIt<PaymentsRepository>(),
      deviceAuthenticator: config.deviceAuthenticator,
      demoAccount: config.demoAccount,
      clock: config.clock,
    );
  }
}
