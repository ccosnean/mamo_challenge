import 'package:flutter/material.dart';
import 'package:payments_app/payments_app.dart';
import 'package:showcase/src/biometrics/biometrics_simulator.dart';
import 'package:showcase/src/ui/panel.dart';

/// The simulated Face ID sensor: choose whether the next scans pass or fail.
class BiometricsPanel extends StatelessWidget {
  const BiometricsPanel({required this.biometrics, super.key});

  final BiometricsSimulator biometrics;

  @override
  Widget build(BuildContext context) {
    return Panel(
      icon: Icons.face_retouching_natural_rounded,
      title: 'Biometrics',
      subtitle: 'Simulated Face ID, outside the app',
      trailing: ValueListenableBuilder<FaceIdPhase?>(
        valueListenable: biometrics.phase,
        builder: (context, phase, _) => phase == FaceIdPhase.scanning
            ? const Text(
                'Scanning…',
                style: TextStyle(
                  color: Workbench.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              )
            : const SizedBox.shrink(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Next scans',
            style: TextStyle(color: Workbench.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<BiometricOutcome>(
            valueListenable: biometrics.outcome,
            builder: (context, outcome, _) => SegmentedButton<BiometricOutcome>(
              showSelectedIcon: false,
              segments: [
                for (final option in BiometricOutcome.values)
                  ButtonSegment(
                    value: option,
                    label: Text(option.label),
                    icon: Icon(
                      option == BiometricOutcome.pass
                          ? Icons.check_rounded
                          : Icons.close_rounded,
                      size: 16,
                    ),
                  ),
              ],
              selected: {outcome},
              onSelectionChanged: (selection) =>
                  biometrics.outcome.value = selection.single,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<List<(DateTime, DeviceAuthResult)>>(
            valueListenable: biometrics.history,
            builder: (context, history, _) => history.isEmpty
                ? const Text(
                    'No scans yet. The app asks when a payment is reviewed.',
                    style: TextStyle(color: Workbench.muted, fontSize: 12),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (time, result) in history)
                        StatRow(
                          label: _time(time),
                          value: result == DeviceAuthResult.success
                              ? 'recognised'
                              : 'not recognised',
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static String _time(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}
