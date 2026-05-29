import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'apple_native_sign_in_client.dart';
import 'google_native_sign_in_client.dart';
import 'zeni_auth_repository.dart';

abstract class ZeniSupabaseAuthClient {
  User? get currentUser;
  Session? get currentSession;

  Stream<User?> authStateChanges();

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  });

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });

  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  });

  Future<void> signOut();
}

class SupabaseGoTrueAuthClient implements ZeniSupabaseAuthClient {
  SupabaseGoTrueAuthClient(this._auth);

  final GoTrueClient _auth;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Session? get currentSession => _auth.currentSession;

  @override
  Stream<User?> authStateChanges() {
    return _auth.onAuthStateChange.map((authState) {
      return authState.session?.user ?? _auth.currentUser;
    });
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _auth.signUp(email: email, password: password);
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  }) {
    return _auth.signInWithIdToken(
      provider: provider,
      idToken: idToken,
      accessToken: accessToken,
      nonce: nonce,
    );
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
  }
}

class SupabaseAuthRepository implements ZeniAuthRepository {
  SupabaseAuthRepository({
    required SupabaseClient? client,
    ZeniSupabaseAuthClient? authClient,
    ZeniGoogleSignInClient? googleSignInClient,
    ZeniAppleSignInClient? appleSignInClient,
  }) : _authClient =
           authClient ?? (client == null ? null : SupabaseGoTrueAuthClient(client.auth)),
       _googleSignInClient = googleSignInClient ?? GoogleNativeSignInClient(),
       _appleSignInClient = appleSignInClient ?? AppleNativeSignInClient();

  final ZeniSupabaseAuthClient? _authClient;
  final ZeniGoogleSignInClient _googleSignInClient;
  final ZeniAppleSignInClient _appleSignInClient;

  @override
  ZeniAuthUser? get currentUser => _mapUser(_authClient?.currentUser);

  @override
  bool get isGoogleSignInAvailable => _googleSignInClient.isConfigured;

  @override
  bool get isAppleSignInAvailable => _appleSignInClient.isSupportedPlatform;

  @override
  Stream<ZeniAuthUser?> authStateChanges() {
    final authClient = _authClient;
    if (authClient == null) {
      return Stream<ZeniAuthUser?>.value(null);
    }

    return authClient.authStateChanges().map(_mapUser);
  }

  @override
  Future<ZeniAuthOperationResult> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final authClient = _authClient;
    if (authClient == null) {
      return const ZeniAuthOperationResult.failure(
        'Supabase Auth não está configurado neste app.',
      );
    }

    try {
      final response = await authClient.signUp(
        email: email,
        password: password,
      );
      final authenticatedUser = _mapUser(
        response.session?.user ?? authClient.currentUser,
      );
      if (authenticatedUser != null) {
        return ZeniAuthOperationResult.success(user: authenticatedUser);
      }

      return ZeniAuthOperationResult.pendingEmailConfirmation(
        user: _mapUser(response.user),
        message: 'Conta criada. Confirme seu e-mail para entrar.',
      );
    } on AuthException catch (error) {
      return ZeniAuthOperationResult.failure(error.message);
    } catch (error) {
      return ZeniAuthOperationResult.failure(error.toString());
    }
  }

  @override
  Future<ZeniAuthOperationResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final authClient = _authClient;
    if (authClient == null) {
      return const ZeniAuthOperationResult.failure(
        'Supabase Auth não está configurado neste app.',
      );
    }

    try {
      final response = await authClient.signInWithPassword(
        email: email,
        password: password,
      );
      return ZeniAuthOperationResult.success(
        user: _mapUser(response.user ?? response.session?.user),
      );
    } on AuthException catch (error) {
      return ZeniAuthOperationResult.failure(error.message);
    } catch (error) {
      return ZeniAuthOperationResult.failure(error.toString());
    }
  }

  @override
  Future<ZeniAuthOperationResult> signInWithGoogle() async {
    final authClient = _authClient;
    if (authClient == null) {
      return const ZeniAuthOperationResult.failure(
        'Supabase Auth não está configurado neste app.',
      );
    }

    try {
      final googleResult = await _googleSignInClient.signIn();
      _debugLog(
        'Google tokens: idToken=${googleResult.idToken.trim().isNotEmpty}, '
        'accessToken=${_normalizeToken(googleResult.accessToken) != null}',
      );
      final response = await authClient.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleResult.idToken,
        accessToken: _normalizeToken(googleResult.accessToken),
      );

      return ZeniAuthOperationResult.success(
        user: _mapUser(response.user ?? response.session?.user),
      );
    } on GoogleSignInException catch (error) {
      _debugLog(
        'Google Sign-In exception: ${error.code.name} ${error.description ?? ''}',
      );
      return ZeniAuthOperationResult.failure(
        error.description ?? _mapGoogleException(error.code),
      );
    } on AuthException catch (error) {
      _debugLog('Supabase Google sign-in error: ${error.message}');
      if (_isGoogleNonceMismatch(error.message)) {
        return const ZeniAuthOperationResult.failure(
          'Não foi possível entrar com Google. Tente novamente ou use e-mail.',
        );
      }
      return const ZeniAuthOperationResult.failure(
        'Não foi possível entrar com Google. Verifique a configuração ou tente e-mail/Apple.',
      );
    } catch (error) {
      _debugLog('Unexpected Google sign-in error: $error');
      return ZeniAuthOperationResult.failure(error.toString());
    }
  }

  @override
  Future<ZeniAuthOperationResult> signInWithApple() async {
    final authClient = _authClient;
    if (authClient == null) {
      return const ZeniAuthOperationResult.failure(
        'Supabase Auth não está configurado neste app.',
      );
    }

    try {
      final appleResult = await _appleSignInClient.signIn();
      final response = await authClient.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: appleResult.idToken,
        nonce: appleResult.rawNonce,
      );

      return ZeniAuthOperationResult.success(
        user: _mapUser(response.user ?? response.session?.user),
      );
    } on SignInWithAppleNotSupportedException {
      return const ZeniAuthOperationResult.failure(
        'Entrar com Apple está disponível apenas em dispositivos Apple compatíveis.',
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      return ZeniAuthOperationResult.failure(
        _mapAppleAuthorizationError(error),
      );
    } on SignInWithAppleException catch (error) {
      return ZeniAuthOperationResult.failure(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } on AuthException catch (error) {
      return ZeniAuthOperationResult.failure(error.message);
    } catch (error) {
      return ZeniAuthOperationResult.failure(error.toString());
    }
  }

  @override
  Future<ZeniAuthOperationResult> signOut() async {
    final authClient = _authClient;
    if (authClient == null) {
      return const ZeniAuthOperationResult.success();
    }

    try {
      await _googleSignInClient.signOut();
      if (authClient.currentSession == null) {
        return const ZeniAuthOperationResult.success();
      }

      await authClient.signOut();
      return const ZeniAuthOperationResult.success();
    } on AuthException catch (error) {
      return ZeniAuthOperationResult.failure(error.message);
    } catch (error) {
      return ZeniAuthOperationResult.failure(error.toString());
    }
  }

  ZeniAuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return ZeniAuthUser(id: user.id, email: user.email);
  }

  String? _normalizeToken(String? token) {
    if (token == null) return null;
    final normalized = token.trim();
    return normalized.isEmpty ? null : normalized;
  }

  bool _isGoogleNonceMismatch(String message) {
    return message.contains(
      'passed nonce and nonce in id_token should either both exist or not',
    );
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[ZeniAuth][Google] $message');
  }

  String _mapGoogleException(GoogleSignInExceptionCode code) {
    return switch (code) {
      GoogleSignInExceptionCode.canceled => 'O login com Google foi cancelado.',
      GoogleSignInExceptionCode.clientConfigurationError =>
        'Google Sign-In não está configurado neste app.',
      GoogleSignInExceptionCode.providerConfigurationError =>
        'A configuração do Google Sign-In está incompleta neste aparelho.',
      GoogleSignInExceptionCode.uiUnavailable =>
        'O login com Google não está disponível agora.',
      GoogleSignInExceptionCode.userMismatch =>
        'Não foi possível usar essa conta Google neste momento.',
      GoogleSignInExceptionCode.unknownError =>
        'Não foi possível concluir o login com Google.',
      GoogleSignInExceptionCode.interrupted =>
        'O login com Google foi interrompido. Tente novamente.',
    };
  }

  String _mapAppleAuthorizationError(
    SignInWithAppleAuthorizationException error,
  ) {
    return switch (error.code) {
      AuthorizationErrorCode.canceled => 'O login com Apple foi cancelado.',
      AuthorizationErrorCode.failed =>
        'Não foi possível concluir o login com Apple.',
      AuthorizationErrorCode.invalidResponse =>
        'A Apple retornou uma resposta inválida.',
      AuthorizationErrorCode.notHandled =>
        'O login com Apple não pôde ser concluído neste momento.',
      AuthorizationErrorCode.notInteractive =>
        'O login com Apple precisa de interação do usuário.',
      AuthorizationErrorCode.unknown =>
        error.message,
    };
  }
}
