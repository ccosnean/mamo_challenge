import 'package:flutter/material.dart';
import 'package:payments_app/payments_app.dart';

/// Production entry point: the real API and platform biometrics. No mocks,
/// no demo account.
///
/// Set the API with `--dart-define=API_BASE_URL=https://…`. For a runnable
/// demo against the mock bank, run the `showcase` package instead.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurePaymentsApp(
    AppConfig(
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.example.invalid',
      ),
      deviceAuthenticator: LocalAuthDeviceAuthenticator(),
    ),
  );
  runApp(const PaymentsApp());
}
