import 'dart:async';

import 'package:zeni/features/auth/data/repositories/zeni_account_repository.dart';
import 'package:zeni/features/auth/data/repositories/zeni_auth_repository.dart';

class FakeZeniAuthRepository implements ZeniAuthRepository {
  FakeZeniAuthRepository({
    ZeniAuthUser? initialUser,
    this.signUpRequiresEmailConfirmation = false,
    this.googleSignInFailureMessage,
    this.appleSignInFailureMessage,
    this.isGoogleSignInAvailableOverride = true,
    this.isAppleSignInAvailableOverride = false,
    this.signInCompleter,
    this.signUpCompleter,
    this.googleSignInCompleter,
    this.appleSignInCompleter,
  }) : _currentUser = initialUser;

  final StreamController<ZeniAuthUser?> _controller =
      StreamController<ZeniAuthUser?>.broadcast();
  final bool signUpRequiresEmailConfirmation;
  final String? googleSignInFailureMessage;
  final String? appleSignInFailureMessage;
  final bool isGoogleSignInAvailableOverride;
  final bool isAppleSignInAvailableOverride;
  final Completer<ZeniAuthOperationResult>? signInCompleter;
  final Completer<ZeniAuthOperationResult>? signUpCompleter;
  final Completer<ZeniAuthOperationResult>? googleSignInCompleter;
  final Completer<ZeniAuthOperationResult>? appleSignInCompleter;
  ZeniAuthUser? _currentUser;
  int signOutCalls = 0;
  int signUpCalls = 0;
  String? lastSignUpDisplayName;

  @override
  ZeniAuthUser? get currentUser => _currentUser;

  @override
  bool get isGoogleSignInAvailable => isGoogleSignInAvailableOverride;

  @override
  bool get isAppleSignInAvailable => isAppleSignInAvailableOverride;

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
    if (signInCompleter != null) {
      final result = await signInCompleter!.future;
      if (result.user != null) {
        _currentUser = result.user;
        _controller.add(_currentUser);
      }
      return result;
    }

    _currentUser = ZeniAuthUser(id: 'signed-in', email: email);
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

  void emitCurrentSessionRefresh() {
    _controller.add(_currentUser);
  }

  void emitStaleAuthEvent(ZeniAuthUser user) {
    _controller.add(user);
  }

  @override
  Future<ZeniAuthOperationResult> signUpWithEmailPassword({
    required String displayName,
    required String email,
    required String password,
  }) async {
    signUpCalls += 1;
    lastSignUpDisplayName = displayName;
    if (signUpCompleter != null) {
      final result = await signUpCompleter!.future;
      if (result.user != null) {
        _currentUser = result.user;
        _controller.add(_currentUser);
      }
      return result;
    }

    if (signUpRequiresEmailConfirmation) {
      return const ZeniAuthOperationResult.pendingEmailConfirmation(
        message: 'Conta criada. Confirme seu e-mail para entrar.',
      );
    }

    _currentUser = ZeniAuthUser(
      id: 'signed-up',
      email: email,
      displayName: displayName,
    );
    _controller.add(_currentUser);
    return ZeniAuthOperationResult.success(user: _currentUser);
  }

  @override
  Future<ZeniAuthOperationResult> signInWithGoogle() async {
    if (googleSignInCompleter != null) {
      final result = await googleSignInCompleter!.future;
      if (result.user != null) {
        _currentUser = result.user;
        _controller.add(_currentUser);
      }
      return result;
    }

    if (googleSignInFailureMessage != null) {
      return ZeniAuthOperationResult.failure(googleSignInFailureMessage!);
    }

    _currentUser = const ZeniAuthUser(
      id: 'google-user',
      email: 'google@zeni.app',
    );
    _controller.add(_currentUser);
    return ZeniAuthOperationResult.success(user: _currentUser);
  }

  @override
  Future<ZeniAuthOperationResult> signInWithApple() async {
    if (appleSignInCompleter != null) {
      final result = await appleSignInCompleter!.future;
      if (result.user != null) {
        _currentUser = result.user;
        _controller.add(_currentUser);
      }
      return result;
    }

    if (appleSignInFailureMessage != null) {
      return ZeniAuthOperationResult.failure(appleSignInFailureMessage!);
    }

    _currentUser = const ZeniAuthUser(
      id: 'apple-user',
      email: 'apple@zeni.app',
    );
    _controller.add(_currentUser);
    return ZeniAuthOperationResult.success(user: _currentUser);
  }

  Future<void> dispose() {
    return _controller.close();
  }
}

class FakeZeniAccountRepository extends ZeniAccountRepository {
  FakeZeniAccountRepository({required this.summary});

  final RemoteFamilySummary? summary;
  int deleteCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<ZeniResolveCurrentFamilyResult> resolveCurrentFamily() async {
    final value = summary;
    return value == null
        ? const ZeniResolveCurrentFamilyResult.notFound(userId: 'test-user')
        : ZeniResolveCurrentFamilyResult.found(
            summary: value,
            userId: 'test-user',
            membershipId: 'membership-test',
          );
  }

  @override
  Future<ZeniCreateInitialFamilyResult> createInitialFamily() async {
    final value = summary;
    return value == null
        ? const ZeniCreateInitialFamilyResult.failure('indisponível')
        : ZeniCreateInitialFamilyResult.alreadyExists(
            summary: value,
            userId: 'test-user',
            membershipId: 'membership-test',
          );
  }

  @override
  Future<RemoteFamilySummary?> getCurrentRemoteFamilySummary() async {
    return summary;
  }

  @override
  Future<ZeniUpdateRemoteFamilyResult> updateRemoteFamilyName({
    required String name,
  }) async {
    if (summary == null) {
      return const ZeniUpdateRemoteFamilyResult.failure(
        'Nenhuma família remota preparada foi encontrada.',
      );
    }

    return ZeniUpdateRemoteFamilyResult.success(
      RemoteFamilySummary(
        familyId: summary!.familyId,
        familyName: name,
        role: summary!.role,
        email: summary!.email,
      ),
    );
  }

  @override
  Future<ZeniDeleteAccountResult> deleteAccountAndRemoteFamily() async {
    deleteCalls += 1;
    return const ZeniDeleteAccountResult.success(
      familyId: 'family-1',
      message: 'Sua conta e os dados da família foram removidos da nuvem.',
    );
  }
}
