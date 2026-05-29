import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/zeni_supabase.dart';
import '../../../family/presentation/providers/remote_children_providers.dart';
import '../../../rewards/presentation/providers/remote_reward_requests_providers.dart';
import '../../../rewards/presentation/providers/remote_rewards_providers.dart';
import '../../../tasks/presentation/providers/remote_mission_logs_providers.dart';
import '../../../tasks/presentation/providers/remote_missions_providers.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/zeni_auth_repository.dart';
import 'zeni_account_providers.dart';

enum ZeniAuthStatus { authenticated, unauthenticated, error }

class ZeniAuthState {
  const ZeniAuthState({required this.status, this.user, this.message});

  const ZeniAuthState.authenticated(ZeniAuthUser user)
    : this(status: ZeniAuthStatus.authenticated, user: user);

  const ZeniAuthState.unauthenticated()
    : this(status: ZeniAuthStatus.unauthenticated);

  const ZeniAuthState.error(String message)
    : this(status: ZeniAuthStatus.error, message: message);

  final ZeniAuthStatus status;
  final ZeniAuthUser? user;
  final String? message;

  bool get isAuthenticated => status == ZeniAuthStatus.authenticated;
}

final authRepositoryProvider = Provider<ZeniAuthRepository>((ref) {
  return SupabaseAuthRepository(client: ZeniSupabaseBootstrap.client);
});

final googleSignInAvailableProvider = Provider<bool>((ref) {
  return ref.watch(authRepositoryProvider).isGoogleSignInAvailable;
});

final appleSignInAvailableProvider = Provider<bool>((ref) {
  return ref.watch(authRepositoryProvider).isAppleSignInAvailable;
});

final authStateProvider =
    NotifierProvider<ZeniAuthStateNotifier, ZeniAuthState>(
      ZeniAuthStateNotifier.new,
    );

class ZeniAuthStateNotifier extends Notifier<ZeniAuthState> {
  late final ZeniAuthRepository _repository;
  StreamSubscription<ZeniAuthUser?>? _subscription;

  @override
  ZeniAuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _subscription?.cancel();
    _subscription = _repository.authStateChanges().listen((user) {
      state = _stateFromUser(user);
    });
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return _stateFromUser(_repository.currentUser);
  }

  void syncFromRepository() {
    state = _stateFromUser(_repository.currentUser);
  }

  void setSignedOut() {
    state = const ZeniAuthState.unauthenticated();
  }

  void setAuthenticated(ZeniAuthUser user) {
    state = ZeniAuthState.authenticated(user);
  }
}

final zeniAuthControllerProvider = Provider<ZeniAuthController>((ref) {
  return ZeniAuthController(ref);
});

class ZeniAuthController {
  const ZeniAuthController(this._ref);

  final Ref _ref;

  Future<ZeniAuthOperationResult> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final result = await _ref
        .read(authRepositoryProvider)
        .signUpWithEmailPassword(email: email, password: password);
    final authState = _ref.read(authStateProvider.notifier);
    if (result.requiresEmailConfirmation) {
      authState.syncFromRepository();
    } else if (result.user != null) {
      authState.setAuthenticated(result.user!);
      final ensured = await _ensureRemoteFamilyIfNeeded(result.user!);
      if (ensured != null) return ensured;
    } else {
      authState.syncFromRepository();
    }
    return result;
  }

  Future<ZeniAuthOperationResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final result = await _ref
        .read(authRepositoryProvider)
        .signInWithEmailPassword(email: email, password: password);
    final authState = _ref.read(authStateProvider.notifier);
    if (result.user != null) {
      authState.setAuthenticated(result.user!);
      final ensured = await _ensureRemoteFamilyIfNeeded(result.user!);
      if (ensured != null) return ensured;
    } else {
      authState.syncFromRepository();
    }
    return result;
  }

  Future<ZeniAuthOperationResult> signInWithGoogle() async {
    final result = await _ref.read(authRepositoryProvider).signInWithGoogle();
    final authState = _ref.read(authStateProvider.notifier);
    if (result.user != null) {
      authState.setAuthenticated(result.user!);
      final ensured = await _ensureRemoteFamilyIfNeeded(result.user!);
      if (ensured != null) return ensured;
    } else {
      authState.syncFromRepository();
    }
    return result;
  }

  Future<ZeniAuthOperationResult> signInWithApple() async {
    final result = await _ref.read(authRepositoryProvider).signInWithApple();
    final authState = _ref.read(authStateProvider.notifier);
    if (result.user != null) {
      authState.setAuthenticated(result.user!);
      final ensured = await _ensureRemoteFamilyIfNeeded(result.user!);
      if (ensured != null) return ensured;
    } else {
      authState.syncFromRepository();
    }
    return result;
  }

  Future<ZeniAuthOperationResult> signOut() async {
    final result = await _ref.read(authRepositoryProvider).signOut();
    if (result.isSuccess) {
      _ref.read(authStateProvider.notifier).setSignedOut();
      _ref.invalidate(remoteFamilySummaryProvider);
      _ref.invalidate(remoteChildrenProvider);
      _ref.invalidate(remoteMissionsProvider);
      _ref.invalidate(remoteRewardsProvider);
      _ref.invalidate(remoteMissionLogsProvider);
      _ref.invalidate(remoteRewardRequestsProvider);
    } else {
      _ref.read(authStateProvider.notifier).syncFromRepository();
    }
    return result;
  }

  Future<ZeniAuthOperationResult?> _ensureRemoteFamilyIfNeeded(
    ZeniAuthUser user,
  ) async {
    if (!ZeniSupabaseBootstrap.state.isAvailable) return null;

    final ensureResult = await _ref
        .read(zeniAccountControllerProvider)
        .ensureRemoteFamilyForCurrentUser();
    if (ensureResult.isSuccess) return null;

    return ZeniAuthOperationResult.failure(
      ensureResult.message ?? 'Não foi possível preparar a família remota.',
    );
  }
}

ZeniAuthState _stateFromUser(ZeniAuthUser? user) {
  if (user == null) {
    return const ZeniAuthState.unauthenticated();
  }

  return ZeniAuthState.authenticated(user);
}
