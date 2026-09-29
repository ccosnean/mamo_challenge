import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mock_bank/mock_bank.dart';
import 'package:payments_app/payments_app.dart';
import 'package:showcase/src/biometrics/biometrics_simulator.dart';
import 'package:showcase/src/console/console_log.dart';
import 'package:showcase/src/showcase_page.dart';
import 'package:showcase/src/ui/panel.dart';

/// The demo user, known to both the login screen and the mock bank.
const DemoAccount _demo = DemoAccount(
  username: 'layla.haddad',
  password: 'palmline-demo-2026',
  name: 'Layla Haddad',
  companyName: 'Palmline Studio FZ-LLC',
  role: 'Finance manager',
);

/// Wires the production app to mock infrastructure, through nothing but
/// `AppConfig`: the app can't tell it isn't talking to a real bank and a
/// real Face ID sensor.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final server = MockBankServer(
    demoUser: (
      username: _demo.username,
      password: _demo.password,
      name: _demo.name,
      companyName: _demo.companyName,
    ),
  );
  final biometrics = BiometricsSimulator();
  final console = ConsoleLog();

  await configurePaymentsApp(
    AppConfig(
      apiBaseUrl: 'https://api.mock-bank.invalid',
      deviceAuthenticator: biometrics,
      transportInterceptors: [MockBankInterceptor(server)],
      logSinks: [console],
      logLevel: Level.ALL,
      // Always masked here, even in a debug run: the showcase exists to show
      // production behaviour, and masking is part of it.
      redactLogs: true,
      demoAccount: _demo,
    ),
  );

  final page = ShowcasePage(
    server: server,
    biometrics: biometrics,
    console: console,
  );

  runApp(
    MaterialApp(
      title: 'Payment approval · Showcase',
      debugShowCheckedModeBanner: false,
      theme: Workbench.theme(),
      // The embedded app owns the browser URL (e.g. `/#/home`). The host has
      // a single page and ignores the URL: every route name, initial or not,
      // resolves to the workbench. (`home` can't be combined with
      // onGenerateInitialRoutes; onGenerateRoute also gives MaterialApp its
      // navigator.)
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => page),
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute<void>(builder: (_) => page),
      ],
    ),
  );
}
