import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/core/device_auth/device_authenticator.dart';

/// [DeviceAuthenticator] backed by the platform: Face ID / Touch ID on iOS,
/// BiometricPrompt on Android. Browsers have no equivalent, so on the web
/// it reports [DeviceAuthResult.unavailable].
final class LocalAuthDeviceAuthenticator implements DeviceAuthenticator {
  LocalAuthDeviceAuthenticator([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  static final Logger _log = Logger('DeviceAuth');

  final LocalAuthentication _auth;

  @override
  Future<DeviceAuthResult> authenticate({required String reason}) async {
    if (kIsWeb) return DeviceAuthResult.unavailable;
    try {
      if (!await _auth.isDeviceSupported()) {
        return DeviceAuthResult.unavailable;
      }
      final passed = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
      return passed ? DeviceAuthResult.success : DeviceAuthResult.failed;
    } on LocalAuthException catch (error) {
      _log.warning('Device auth ended: ${error.code.name}');
      return switch (error.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback =>
          DeviceAuthResult.cancelled,
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable ||
        LocalAuthExceptionCode.uiUnavailable => DeviceAuthResult.unavailable,
        _ => DeviceAuthResult.failed,
      };
    } on PlatformException catch (error) {
      _log.warning('Device auth unavailable', error.code);
      return DeviceAuthResult.unavailable;
    }
  }
}
