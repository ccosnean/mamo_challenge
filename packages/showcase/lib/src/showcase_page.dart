import 'dart:math' as math;

import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import 'package:mock_bank/mock_bank.dart';
import 'package:payments_app/payments_app.dart';
import 'package:showcase/src/bank/bank_panel.dart';
import 'package:showcase/src/biometrics/biometrics_panel.dart';
import 'package:showcase/src/biometrics/biometrics_simulator.dart';
import 'package:showcase/src/biometrics/face_id_overlay.dart';
import 'package:showcase/src/console/console_log.dart';
import 'package:showcase/src/console/console_panel.dart';
import 'package:showcase/src/ui/panel.dart';

/// The workbench: the app in a device on the left, the mock modules on the
/// right, the console below them.
class ShowcasePage extends StatelessWidget {
  const ShowcasePage({
    required this.server,
    required this.biometrics,
    required this.console,
    super.key,
  });

  final MockBankServer server;
  final BiometricsSimulator biometrics;
  final ConsoleLog console;

  static const double _sideWidth = 460;

  /// Room for the side column plus a phone that's still comfortable to use.
  static const double _minWidth = _sideWidth + 500;

  @override
  Widget build(BuildContext context) {
    // The phone's screen: the app, plus what the OS draws over it.
    final device = FaceIdOverlay(
      biometrics: biometrics,
      child: const PaymentsApp(),
    );
    final modules = [
      BankPanel(server: server),
      const SizedBox(height: 12),
      BiometricsPanel(biometrics: biometrics),
    ];

    return Scaffold(
      // Always the workbench. A window narrower than that scrolls sideways
      // rather than rearranging it.
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(constraints.maxWidth, _minWidth),
            height: constraints.maxHeight,
            child: Column(
              children: [
                const _Header(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: DeviceFrame(
                              device: Devices.ios.iPhone15Pro,
                              screen: device,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: _sideWidth,
                        child: _SideColumn(modules: modules, console: console),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modules on top, the console below. The console collapses to its header,
/// giving the modules the whole column.
class _SideColumn extends StatefulWidget {
  const _SideColumn({required this.modules, required this.console});

  final List<Widget> modules;
  final ConsoleLog console;

  @override
  State<_SideColumn> createState() => _SideColumnState();
}

class _SideColumnState extends State<_SideColumn> {
  bool _consoleOpen = true;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Workbench.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: widget.modules,
            ),
          ),
          if (_consoleOpen)
            Expanded(
              child: ConsolePanel(
                log: widget.console,
                onToggle: () => setState(() => _consoleOpen = false),
              ),
            )
          else
            ConsolePanel(
              log: widget.console,
              expanded: false,
              onToggle: () => setState(() => _consoleOpen = true),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Workbench.border)),
      ),
      child: const Row(
        children: [
          Text(
            'Payment approval',
            style: TextStyle(
              color: Workbench.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'The app runs in isolation on the device. Everything around it '
              'is mock infrastructure: bank, biometrics, logs.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Workbench.muted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
