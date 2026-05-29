import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class ZeniAppleSignInResult {
  const ZeniAppleSignInResult({
    required this.idToken,
    required this.rawNonce,
    this.email,
  });

  final String idToken;
  final String rawNonce;
  final String? email;
}

abstract class ZeniAppleSignInClient {
  bool get isSupportedPlatform;

  Future<ZeniAppleSignInResult> signIn();
}

class AppleNativeSignInClient implements ZeniAppleSignInClient {
  @override
  bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  Future<ZeniAppleSignInResult> signIn() async {
    if (!isSupportedPlatform) {
      throw const SignInWithAppleNotSupportedException(
        message:
            'Entrar com Apple está disponível apenas em dispositivos Apple compatíveis.',
      );
    }

    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw const SignInWithAppleNotSupportedException(
        message:
            'Entrar com Apple está disponível apenas em dispositivos Apple compatíveis.',
      );
    }

    final rawNonce = generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null || idToken.trim().isEmpty) {
      throw const SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.unknown,
        message: 'Não foi possível obter o token da Apple.',
      );
    }

    return ZeniAppleSignInResult(
      idToken: idToken,
      rawNonce: rawNonce,
      email: credential.email,
    );
  }
}
