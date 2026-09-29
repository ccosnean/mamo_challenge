/// Outcome of a device authentication attempt (Face ID, fingerprint, …).
enum DeviceAuthResult {
  success,

  /// The biometric didn't match.
  failed,

  /// The user dismissed the prompt. Not an error: nothing to show.
  cancelled,

  /// No biometrics enrolled or no hardware.
  unavailable,
}

/// Proves the person holding the device is its owner before sensitive data
/// is revealed.
///
/// Production uses the platform's biometrics (`LocalAuthDeviceAuthenticator`);
/// a host can supply any other implementation through `AppConfig`.
// An interface on purpose: implementations are chosen by the host.
// ignore: one_member_abstracts
abstract interface class DeviceAuthenticator {
  Future<DeviceAuthResult> authenticate({required String reason});
}
