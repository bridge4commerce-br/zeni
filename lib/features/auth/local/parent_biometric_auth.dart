import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

const parentBiometricsUnavailableMessage =
    'Biometria indisponível neste dispositivo. Use o PIN para proteger o modo responsável.';

final parentBiometricAuthProvider = Provider<ParentBiometricAuth>((ref) {
  return LocalParentBiometricAuth();
});

abstract class ParentBiometricAuth {
  Future<ParentBiometricAvailability> checkAvailability();

  Future<ParentBiometricAuthResult> authenticate();
}

class LocalParentBiometricAuth implements ParentBiometricAuth {
  LocalParentBiometricAuth({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  @override
  Future<ParentBiometricAvailability> checkAvailability() async {
    try {
      final canCheckBiometrics = await _authentication.canCheckBiometrics;
      final isDeviceSupported = await _authentication.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        return ParentBiometricAvailability.unavailable(
          'Este aparelho não oferece biometria para proteger o perfil responsável.',
        );
      }

      final biometrics = await _authentication.getAvailableBiometrics();
      if (biometrics.isEmpty) {
        return ParentBiometricAvailability.unavailable(
          'Ative Face ID, Touch ID ou impressão digital no aparelho para usar biometria.',
        );
      }

      return const ParentBiometricAvailability.available();
    } on LocalAuthException catch (error) {
      return ParentBiometricAvailability.unavailable(
        _messageForException(error),
      );
    } on PlatformException {
      return const ParentBiometricAvailability.unavailable(
        parentBiometricsUnavailableMessage,
      );
    } on Exception {
      return const ParentBiometricAvailability.unavailable(
        parentBiometricsUnavailableMessage,
      );
    }
  }

  @override
  Future<ParentBiometricAuthResult> authenticate() async {
    try {
      final available = await checkAvailability();
      if (!available.isAvailable) {
        return ParentBiometricAuthResult.unavailable(available.message);
      }

      final didAuthenticate = await _authentication.authenticate(
        localizedReason: 'Confirme sua identidade para entrar como responsável',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        return const ParentBiometricAuthResult.authenticated();
      }

      return const ParentBiometricAuthResult.fallbackToPin();
    } on LocalAuthException catch (error) {
      return ParentBiometricAuthResult.unavailable(_messageForException(error));
    } on PlatformException {
      return const ParentBiometricAuthResult.unavailable(
        parentBiometricsUnavailableMessage,
      );
    } on Exception {
      return const ParentBiometricAuthResult.unavailable(
        parentBiometricsUnavailableMessage,
      );
    }
  }

  String _messageForException(LocalAuthException error) {
    switch (error.code) {
      case LocalAuthExceptionCode.noBiometricHardware:
        return 'Este aparelho não tem sensor biométrico disponível.';
      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return 'Nenhuma biometria está cadastrada neste aparelho.';
      case LocalAuthExceptionCode.biometricLockout:
      case LocalAuthExceptionCode.temporaryLockout:
        return 'A biometria está temporariamente bloqueada. Use seu PIN para continuar.';
      case LocalAuthExceptionCode.noCredentialsSet:
        return 'Configure o bloqueio de tela do aparelho antes de ativar a biometria.';
      default:
        return 'Não foi possível usar a biometria agora. Você ainda pode entrar com o PIN.';
    }
  }
}

class ParentBiometricAvailability {
  const ParentBiometricAvailability._({
    required this.isAvailable,
    this.message,
  });

  const ParentBiometricAvailability.available() : this._(isAvailable: true);

  const ParentBiometricAvailability.unavailable(String message)
    : this._(isAvailable: false, message: message);

  final bool isAvailable;
  final String? message;
}

enum ParentBiometricAuthStatus { authenticated, fallbackToPin, unavailable }

class ParentBiometricAuthResult {
  const ParentBiometricAuthResult._({required this.status, this.message});

  const ParentBiometricAuthResult.authenticated()
    : this._(status: ParentBiometricAuthStatus.authenticated);

  const ParentBiometricAuthResult.fallbackToPin()
    : this._(status: ParentBiometricAuthStatus.fallbackToPin);

  const ParentBiometricAuthResult.unavailable(String? message)
    : this._(status: ParentBiometricAuthStatus.unavailable, message: message);

  final ParentBiometricAuthStatus status;
  final String? message;

  bool get isAuthenticated => status == ParentBiometricAuthStatus.authenticated;
}
