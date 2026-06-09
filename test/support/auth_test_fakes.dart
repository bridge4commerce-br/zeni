import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeni/features/auth/data/repositories/apple_native_sign_in_client.dart';
import 'package:zeni/features/auth/data/repositories/google_native_sign_in_client.dart';
import 'package:zeni/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:zeni/features/auth/data/repositories/zeni_account_repository.dart';
import 'package:zeni/features/auth/data/repositories/zeni_auth_repository.dart';

class TestAuthRepository implements ZeniAuthRepository {
  final StreamController<ZeniAuthUser?> _controller =
      StreamController<ZeniAuthUser?>.broadcast();
  ZeniAuthUser? _currentUser;
  int signOutCalls = 0;

  @override
  bool get isGoogleSignInAvailable => true;

  @override
  bool get isAppleSignInAvailable => true;

  @override
  ZeniAuthUser? get currentUser => _currentUser;

  @override
  Stream<ZeniAuthUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<ZeniAuthOperationResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = ZeniAuthUser(id: 'user-1', email: email);
    _controller.add(_currentUser);
    return ZeniAuthOperationResult.success(user: _currentUser);
  }

  @override
  Future<ZeniAuthOperationResult> signOut() async {
    signOutCalls += 1;
    _currentUser = null;
    _controller.add(null);
    return const ZeniAuthOperationResult.success();
  }

  @override
  Future<ZeniAuthOperationResult> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = ZeniAuthUser(id: 'user-2', email: email);
    _controller.add(_currentUser);
    return ZeniAuthOperationResult.success(user: _currentUser);
  }

  @override
  Future<ZeniAuthOperationResult> signInWithGoogle() async {
    _currentUser = const ZeniAuthUser(
      id: 'google-user',
      email: 'google@zeni.app',
    );
    _controller.add(_currentUser);
    return ZeniAuthOperationResult.success(user: _currentUser);
  }

  @override
  Future<ZeniAuthOperationResult> signInWithApple() async {
    _currentUser = const ZeniAuthUser(
      id: 'apple-user',
      email: 'apple@zeni.app',
    );
    _controller.add(_currentUser);
    return ZeniAuthOperationResult.success(user: _currentUser);
  }

  Future<void> dispose() => _controller.close();
}

class FakeAccountRepository implements ZeniAccountRepository {
  FakeAccountRepository({
    this.ensureResult = const ZeniEnsureRemoteFamilyResult.success(
      RemoteFamilySummary(
        familyId: 'family-1',
        familyName: 'Minha família',
        role: 'owner',
      ),
    ),
    this.updateResult = const ZeniUpdateRemoteFamilyResult.success(
      RemoteFamilySummary(
        familyId: 'family-1',
        familyName: 'Minha família',
        role: 'owner',
      ),
    ),
    this.deleteResult = const ZeniDeleteAccountResult.success(
      familyId: 'family-1',
      message: 'Sua conta e os dados da família foram removidos da nuvem.',
    ),
  });

  final ZeniEnsureRemoteFamilyResult ensureResult;
  final ZeniUpdateRemoteFamilyResult updateResult;
  final ZeniDeleteAccountResult deleteResult;
  int ensureCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<RemoteFamilySummary?> getCurrentRemoteFamilySummary() async {
    return null;
  }

  @override
  Future<ZeniEnsureRemoteFamilyResult>
  ensureRemoteFamilyForCurrentUser() async {
    ensureCalls += 1;
    return ensureResult;
  }

  @override
  Future<ZeniUpdateRemoteFamilyResult> updateRemoteFamilyName({
    required String familyId,
    required String name,
  }) async {
    updateCalls += 1;
    return updateResult;
  }

  @override
  Future<ZeniDeleteAccountResult> deleteAccountAndRemoteFamily() async {
    deleteCalls += 1;
    return deleteResult;
  }
}

class FakeSupabaseAuthClient implements ZeniSupabaseAuthClient {
  FakeSupabaseAuthClient({this.signInWithIdTokenError});

  final AuthException? signInWithIdTokenError;
  OAuthProvider? lastProvider;
  String? lastIdToken;
  String? lastAccessToken;
  String? lastNonce;
  User? _currentUser;
  Session? _currentSession;
  final StreamController<User?> _controller =
      StreamController<User?>.broadcast();

  @override
  User? get currentUser => _currentUser;

  @override
  Session? get currentSession => _currentSession;

  @override
  Stream<User?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  }) async {
    lastProvider = provider;
    lastIdToken = idToken;
    lastAccessToken = accessToken;
    lastNonce = nonce;

    if (signInWithIdTokenError != null) {
      throw signInWithIdTokenError!;
    }

    final email = provider == OAuthProvider.google
        ? 'google@zeni.app'
        : 'apple@zeni.app';
    final user = User(
      id: '${provider.name}-user',
      appMetadata: const {},
      userMetadata: null,
      aud: 'authenticated',
      email: email,
      createdAt: '2026-05-28T00:00:00.000Z',
    );
    final session = Session(
      accessToken: 'session-token',
      tokenType: 'bearer',
      user: user,
    );
    _currentUser = user;
    _currentSession = session;
    _controller.add(user);
    return AuthResponse(session: session, user: user);
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _currentSession = null;
    _controller.add(null);
  }
}

class FakeGoogleSignInClient implements ZeniGoogleSignInClient {
  const FakeGoogleSignInClient.success(this.result) : error = null;
  const FakeGoogleSignInClient.failure(this.error) : result = null;

  final ZeniGoogleSignInResult? result;
  final GoogleSignInException? error;

  @override
  bool get isConfigured => true;

  @override
  Future<ZeniGoogleSignInResult> signIn() async {
    if (error != null) throw error!;
    return result!;
  }

  @override
  Future<void> signOut() async {}
}

class FakeAppleSignInClient implements ZeniAppleSignInClient {
  const FakeAppleSignInClient.success(this.result);

  final ZeniAppleSignInResult result;

  @override
  bool get isSupportedPlatform => true;

  @override
  Future<ZeniAppleSignInResult> signIn() async => result;
}
