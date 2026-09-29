import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:payments_app/payments_app.dart';

/// What the simulated face scan concludes.
enum BiometricOutcome {
  pass('Pass'),
  fail('Fail');

  const BiometricOutcome(this.label);

  final String label;
}

/// Where the on-screen Face ID animation is.
enum FaceIdPhase { scanning, succeeded, failed }

/// The device's Face ID sensor, simulated outside the app.
///
/// The app only sees a [DeviceAuthenticator]. Each request plays the
/// system-style animation (scan, then a check or a cross) and resolves with
/// the [outcome] chosen in the Biometrics panel.
final class BiometricsSimulator implements DeviceAuthenticator {
  static const Duration _scanDuration = Duration(milliseconds: 900);
  static const Duration _resultDuration = Duration(milliseconds: 700);

  final ValueNotifier<BiometricOutcome> outcome = ValueNotifier(
    BiometricOutcome.pass,
  );

  /// The animation on the device, or null when idle.
  final ValueNotifier<FaceIdPhase?> phase = ValueNotifier(null);

  /// Latest results, newest first.
  final ValueNotifier<List<(DateTime, DeviceAuthResult)>> history =
      ValueNotifier(const []);

  @override
  Future<DeviceAuthResult> authenticate({required String reason}) async {
    phase.value = FaceIdPhase.scanning;
    await Future<void>.delayed(_scanDuration);

    final passed = outcome.value == BiometricOutcome.pass;
    phase.value = passed ? FaceIdPhase.succeeded : FaceIdPhase.failed;
    await Future<void>.delayed(_resultDuration);
    phase.value = null;

    final result = passed ? DeviceAuthResult.success : DeviceAuthResult.failed;
    history.value = [(DateTime.now(), result), ...history.value.take(4)];
    return result;
  }
}
