import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class NativeSecurityService {
  static const MethodChannel _channel = MethodChannel('com.ourspace.app/security');
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<void> enableFlagSecure() async {
    try {
      await _channel.invokeMethod('enableFlagSecure');
    } catch (_) {}
  }

  static Future<void> disableFlagSecure() async {
    try {
      await _channel.invokeMethod('disableFlagSecure');
    } catch (_) {}
  }

  static Future<bool> isBiometricsAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticateBiometrics(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
