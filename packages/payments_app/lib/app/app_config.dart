import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/core/device_auth/device_authenticator.dart';
import 'package:payments_app/core/logging/log_sink.dart';
import 'package:payments_app/features/auth/presentation/demo_account.dart';

/// Everything a host decides about the app. Production uses the defaults
/// plus a real API URL and platform biometrics; the showcase and tests plug
/// in a mock bank, simulated biometrics and their own log viewer.
///
/// The app never knows which it got.
@immutable
final class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.deviceAuthenticator,
    this.transportInterceptors = const [],
    this.logSinks = const [],
    this.logLevel = Level.INFO,
    this.redactLogs = !kDebugMode,
    this.demoAccount,
    this.pollInterval = const Duration(seconds: 5),
    this.clock = const Clock(),
  });

  final String apiBaseUrl;

  /// Face ID / fingerprint, or a simulation of it.
  final DeviceAuthenticator deviceAuthenticator;

  /// Added after the app's own interceptors (auth header, logging), so they
  /// see every call first. A mock bank that answers requests goes here.
  final List<Interceptor> transportInterceptors;

  /// Extra destinations for log entries, besides the debug console.
  final List<LogSink> logSinks;
  final Level logLevel;

  /// Mask sensitive data before any sink sees it.
  final bool redactLogs;

  /// Shown on the login screen for one-tap sign-in. Null in production.
  final DemoAccount? demoAccount;

  /// How often pending requests and balances are re-read while signed in.
  final Duration pollInterval;

  final Clock clock;
}
