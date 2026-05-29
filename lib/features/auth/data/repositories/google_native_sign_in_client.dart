import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

const _zeniGoogleScopes = <String>['email', 'profile'];

class ZeniGoogleSignInConfig {
  const ZeniGoogleSignInConfig({
    required this.serverClientId,
    this.clientId,
  });

  factory ZeniGoogleSignInConfig.fromEnvironment() {
    return const ZeniGoogleSignInConfig(
      serverClientId: String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
      clientId: String.fromEnvironment('GOOGLE_CLIENT_ID'),
    );
  }

  final String serverClientId;
  final String? clientId;

  bool get requiresClientId =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  bool get isConfigured {
    if (serverClientId.trim().isEmpty) return false;
    if (requiresClientId && (clientId == null || clientId!.trim().isEmpty)) {
      return false;
    }
    return true;
  }

  String get missingConfigurationMessage {
    if (serverClientId.trim().isEmpty) {
      return 'Defina GOOGLE_SERVER_CLIENT_ID para habilitar o login com Google.';
    }
    if (requiresClientId && (clientId == null || clientId!.trim().isEmpty)) {
      return 'Defina GOOGLE_CLIENT_ID para habilitar o login com Google neste dispositivo Apple.';
    }
    return 'Google Sign-In não está configurado neste app.';
  }
}

class ZeniGoogleSignInResult {
  const ZeniGoogleSignInResult({
    required this.idToken,
    this.accessToken,
    this.email,
  });

  final String idToken;
  final String? accessToken;
  final String? email;
}

abstract class ZeniGoogleSignInClient {
  bool get isConfigured;

  Future<ZeniGoogleSignInResult> signIn();

  Future<void> signOut();
}

class GoogleNativeSignInClient implements ZeniGoogleSignInClient {
  GoogleNativeSignInClient({
    ZeniGoogleSignInConfig? config,
    GoogleSignIn? googleSignIn,
  }) : _config = config ?? ZeniGoogleSignInConfig.fromEnvironment(),
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final ZeniGoogleSignInConfig _config;
  final GoogleSignIn _googleSignIn;
  bool _isInitialized = false;

  @override
  bool get isConfigured => _config.isConfigured;

  @override
  Future<ZeniGoogleSignInResult> signIn() async {
    _debugLog(
      'Google config: serverClientId=${_config.serverClientId.trim().isNotEmpty}, '
      'clientId=${(_config.clientId ?? '').trim().isNotEmpty}',
    );
    if (!isConfigured) {
      throw GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: _config.missingConfigurationMessage,
      );
    }

    await _ensureInitialized();
    final account = await _googleSignIn.authenticate();
    _debugLog('Google account authenticated: yes');
    final authentication = account.authentication;
    final idToken = authentication.idToken;
    _debugLog('Google idToken present: ${idToken != null && idToken.trim().isNotEmpty}');
    if (idToken == null || idToken.trim().isEmpty) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'Não foi possível obter o ID token do Google.',
      );
    }

    String? accessToken;
    try {
      final authorization = await account.authorizationClient
          .authorizationForScopes(_zeniGoogleScopes);
      accessToken = authorization?.accessToken;
    } on GoogleSignInException catch (error) {
      _debugLog(
        'Google accessToken authorization failed: ${error.code.name}'
        ' ${error.description ?? ''}',
      );
    } catch (error) {
      _debugLog('Google accessToken authorization failed: $error');
    }
    _debugLog(
      'Google accessToken present: ${accessToken != null && accessToken.trim().isNotEmpty}',
    );

    return ZeniGoogleSignInResult(
      idToken: idToken,
      accessToken: accessToken,
      email: account.email,
    );
  }

  @override
  Future<void> signOut() async {
    if (!_isInitialized) return;
    await _googleSignIn.signOut();
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    await _googleSignIn.initialize(
      clientId: _config.clientId?.trim().isEmpty ?? true
          ? null
          : _config.clientId!.trim(),
      serverClientId: _config.serverClientId.trim(),
    );
    _isInitialized = true;
    _debugLog('Google Sign-In initialized');
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[ZeniGoogleSignIn] $message');
  }
}
