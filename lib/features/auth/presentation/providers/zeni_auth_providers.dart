import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/zeni_supabase.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../family/presentation/providers/remote_children_providers.dart';
import '../../../rewards/presentation/providers/remote_reward_requests_providers.dart';
import '../../../rewards/presentation/providers/remote_rewards_providers.dart';
import '../../../tasks/presentation/providers/remote_mission_logs_providers.dart';
import '../../../tasks/presentation/providers/remote_missions_providers.dart';
import '../../../tasks/data/repositories/remote_missions_repository.dart';
import '../../../sync/data/mappers/remote_device_bootstrap_mapper.dart';
import '../../../sync/domain/family_identity.dart';
import '../../../sync/presentation/providers/family_identity_guard.dart';
import '../../data/repositories/zeni_account_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/zeni_auth_repository.dart';
import 'zeni_account_providers.dart';

enum ZeniAuthStatus { authenticated, unauthenticated, error }

enum ZeniFamilyIdentityAccess { pending, ready, blocked }

class ZeniAuthState {
  const ZeniAuthState({
    required this.status,
    this.user,
    this.message,
    this.familyIdentityAccess = ZeniFamilyIdentityAccess.pending,
  });

  const ZeniAuthState.authenticated(
    ZeniAuthUser user, {
    ZeniFamilyIdentityAccess familyIdentityAccess =
        ZeniFamilyIdentityAccess.pending,
  }) : this(
         status: ZeniAuthStatus.authenticated,
         user: user,
         familyIdentityAccess: familyIdentityAccess,
       );

  const ZeniAuthState.unauthenticated()
    : this(status: ZeniAuthStatus.unauthenticated);

  const ZeniAuthState.error(String message)
    : this(status: ZeniAuthStatus.error, message: message);

  final ZeniAuthStatus status;
  final ZeniAuthUser? user;
  final String? message;
  final ZeniFamilyIdentityAccess familyIdentityAccess;

  bool get isAuthenticated => status == ZeniAuthStatus.authenticated;
  bool get isFamilyIdentityBlocked =>
      isAuthenticated &&
      familyIdentityAccess == ZeniFamilyIdentityAccess.blocked;
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
    _subscription = _repository.authStateChanges().listen(_applyAuthEvent);
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

  void setFamilyIdentityReady(ZeniAuthUser user) {
    state = ZeniAuthState.authenticated(
      user,
      familyIdentityAccess: ZeniFamilyIdentityAccess.ready,
    );
  }

  void setFamilyIdentityBlocked(ZeniAuthUser user) {
    state = ZeniAuthState.authenticated(
      user,
      familyIdentityAccess: ZeniFamilyIdentityAccess.blocked,
    );
  }

  void _applyAuthEvent(ZeniAuthUser? eventUser) {
    final sessionUser = _repository.currentUser;
    if (eventUser == null || sessionUser == null) {
      state = const ZeniAuthState.unauthenticated();
      return;
    }

    if (eventUser.id != sessionUser.id) return;
    if (state.user?.id == sessionUser.id) {
      state = ZeniAuthState.authenticated(
        sessionUser,
        familyIdentityAccess: state.familyIdentityAccess,
      );
      return;
    }

    state = ZeniAuthState.authenticated(sessionUser);
  }
}

final zeniAuthControllerProvider = Provider<ZeniAuthController>((ref) {
  return ZeniAuthController(ref);
});

class ZeniAuthController {
  ZeniAuthController(this._ref);

  final Ref _ref;
  Future<ZeniAuthOperationResult?>? _familyPreparationInFlight;
  String? _familyPreparationUserId;

  Future<ZeniAuthOperationResult> prepareCurrentSession() async {
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      _ref.read(authStateProvider.notifier).setSignedOut();
      return const ZeniAuthOperationResult.failure(
        'Faça login para continuar.',
      );
    }

    _ref.read(authStateProvider.notifier).setAuthenticated(user);
    final prepared = await _prepareCanonicalFamily(user);
    if (prepared != null) {
      _recordFamilyPreparation(user, prepared);
      return prepared;
    }
    _recordFamilyPreparation(user, null);
    return ZeniAuthOperationResult.success(user: user);
  }

  Future<ZeniAuthOperationResult> signUpWithEmailPassword({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final normalizedName = displayName.trim();
    if (normalizedName.isEmpty) {
      return const ZeniAuthOperationResult.failure('Informe seu nome.');
    }
    final result = await _ref
        .read(authRepositoryProvider)
        .signUpWithEmailPassword(
          displayName: normalizedName,
          email: email,
          password: password,
        );
    final authState = _ref.read(authStateProvider.notifier);
    if (result.requiresEmailConfirmation) {
      authState.syncFromRepository();
    } else if (result.user != null) {
      authState.setAuthenticated(result.user!);
      final prepared = await _prepareCanonicalFamily(result.user!);
      if (prepared != null) {
        _recordFamilyPreparation(result.user!, prepared);
        return prepared;
      }
      _recordFamilyPreparation(
        result.user!,
        result.issue == null ? null : result,
      );
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
      final prepared = await _prepareCanonicalFamily(result.user!);
      if (prepared != null) {
        _recordFamilyPreparation(result.user!, prepared);
        return prepared;
      }
      _recordFamilyPreparation(
        result.user!,
        result.issue == null ? null : result,
      );
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
      final prepared = await _prepareCanonicalFamily(result.user!);
      if (prepared != null) {
        _recordFamilyPreparation(result.user!, prepared);
        return prepared;
      }
      _recordFamilyPreparation(
        result.user!,
        result.issue == null ? null : result,
      );
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
      final prepared = await _prepareCanonicalFamily(result.user!);
      if (prepared != null) {
        _recordFamilyPreparation(result.user!, prepared);
        return prepared;
      }
      _recordFamilyPreparation(
        result.user!,
        result.issue == null ? null : result,
      );
    } else {
      authState.syncFromRepository();
    }
    return result;
  }

  Future<ZeniAuthOperationResult> signOut() async {
    final result = await _ref.read(authRepositoryProvider).signOut();
    if (result.isSuccess) {
      _ref.read(authStateProvider.notifier).setSignedOut();
      _ref.invalidate(remoteFamilyResolutionProvider);
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

  Future<ZeniAuthOperationResult?> _prepareCanonicalFamily(
    ZeniAuthUser user,
  ) async {
    if (!ZeniSupabaseBootstrap.state.isAvailable) {
      return null;
    }

    final inFlight = _familyPreparationInFlight;
    if (inFlight != null && _familyPreparationUserId == user.id) {
      return await inFlight;
    }

    final operation = _resolveOrCreateCanonicalFamily(user);
    _familyPreparationInFlight = operation;
    _familyPreparationUserId = user.id;
    try {
      return await operation;
    } finally {
      if (identical(_familyPreparationInFlight, operation)) {
        _familyPreparationInFlight = null;
        _familyPreparationUserId = null;
      }
    }
  }

  Future<ZeniAuthOperationResult?> _resolveOrCreateCanonicalFamily(
    ZeniAuthUser user,
  ) async {
    await _ref
        .read(zeniAccountControllerProvider)
        .initializeCurrentAccountProfile(
          suggestedDisplayName: user.displayName,
        );
    if (!_isCurrentSession(user)) {
      return const ZeniAuthOperationResult.failure(
        canonicalFamilySessionChangedMessage,
      );
    }

    final resolution = await _ref
        .read(zeniAccountControllerProvider)
        .resolveCurrentFamily();
    if (!_isCurrentSession(user)) {
      return const ZeniAuthOperationResult.failure(
        canonicalFamilySessionChangedMessage,
      );
    }

    switch (resolution.status) {
      case ZeniResolveCurrentFamilyStatus.found:
        if (resolution.summary == null) {
          return const ZeniAuthOperationResult.failure(
            canonicalFamilyInconsistentMessage,
          );
        }
        await _ref.read(zeniAppStateControllerProvider.future);
        final identity = FamilyIdentityGuard(
          _ref,
          familyId: resolution.summary!.familyId,
        );
        if (!identity.canSync && !identity.canBootstrap) {
          return ZeniAuthOperationResult.localFamilyConflict(user: user);
        }
        if (identity.canBootstrap) {
          return _bootstrapCanonicalFamily(
            user: user,
            remoteFamily: resolution.summary!,
          );
        }
        return null;
      case ZeniResolveCurrentFamilyStatus.ambiguous:
        return const ZeniAuthOperationResult.failure(
          canonicalFamilyAmbiguousMessage,
        );
      case ZeniResolveCurrentFamilyStatus.inconsistent:
        return const ZeniAuthOperationResult.failure(
          canonicalFamilyInconsistentMessage,
        );
      case ZeniResolveCurrentFamilyStatus.failure:
        return ZeniAuthOperationResult.failure(
          resolution.message ??
              'Não foi possível identificar a família remota agora.',
        );
      case ZeniResolveCurrentFamilyStatus.notFound:
        break;
    }

    final localState = await _ref.read(zeniAppStateControllerProvider.future);
    if (!FamilyIdentity.isEmptySafe(localState)) {
      return ZeniAuthOperationResult.localFamilyConflict(user: user);
    }
    if (!_isCurrentSession(user)) {
      return const ZeniAuthOperationResult.failure(
        canonicalFamilySessionChangedMessage,
      );
    }

    final createResult = await _ref
        .read(zeniAccountControllerProvider)
        .createInitialFamily();
    if (!_isCurrentSession(user)) {
      return const ZeniAuthOperationResult.failure(
        canonicalFamilySessionChangedMessage,
      );
    }

    switch (createResult.status) {
      case ZeniCreateInitialFamilyStatus.created:
      case ZeniCreateInitialFamilyStatus.alreadyExists:
        if (createResult.summary == null) {
          return const ZeniAuthOperationResult.failure(
            canonicalFamilyInconsistentMessage,
          );
        }
        return _bootstrapCanonicalFamily(
          user: user,
          remoteFamily: createResult.summary!,
        );
      case ZeniCreateInitialFamilyStatus.ambiguous:
        return const ZeniAuthOperationResult.failure(
          canonicalFamilyAmbiguousMessage,
        );
      case ZeniCreateInitialFamilyStatus.inconsistent:
        return const ZeniAuthOperationResult.failure(
          canonicalFamilyInconsistentMessage,
        );
      case ZeniCreateInitialFamilyStatus.failure:
        return ZeniAuthOperationResult.failure(
          createResult.message ??
              'Não foi possível criar a família remota agora.',
        );
    }
  }

  Future<ZeniAuthOperationResult?> _bootstrapCanonicalFamily({
    required ZeniAuthUser user,
    required RemoteFamilySummary remoteFamily,
  }) async {
    final localState = await _ref.read(zeniAppStateControllerProvider.future);
    final identity = FamilyIdentityGuard(_ref, familyId: remoteFamily.familyId);
    if (!FamilyIdentity.isEmptySafe(localState) || !identity.canBootstrap) {
      return ZeniAuthOperationResult.localFamilyConflict(user: user);
    }

    try {
      final remoteChildren = await _ref
          .read(remoteChildrenRepositoryProvider)
          .getRemoteChildren(familyId: remoteFamily.familyId);
      final remoteMissions = remoteChildren.isEmpty
          ? const <RemoteMissionSummary>[]
          : await _ref
                .read(remoteMissionsRepositoryProvider)
                .getRemoteMissions(familyId: remoteFamily.familyId);
      final remoteRewards = await _ref
          .read(remoteRewardsRepositoryProvider)
          .getRemoteRewards(familyId: remoteFamily.familyId);

      if (!_isCurrentSession(user) ||
          !identity.canBootstrap ||
          remoteChildren.any(
            (item) => item.familyId != remoteFamily.familyId,
          ) ||
          remoteMissions.any(
            (item) => item.familyId != remoteFamily.familyId,
          ) ||
          remoteRewards.any((item) => item.familyId != remoteFamily.familyId)) {
        return const ZeniAuthOperationResult.failure(
          canonicalFamilySessionChangedMessage,
        );
      }

      final payload = const RemoteDeviceBootstrapMapper().map(
        remoteFamily: remoteFamily,
        remoteChildren: remoteChildren,
        remoteMissions: remoteMissions,
        remoteRewards: remoteRewards,
        localInviteCode: localState.family.inviteCode,
      );
      final applied = await _ref
          .read(zeniAppStateControllerProvider.notifier)
          .applyDeviceBootstrapIfEmpty(payload);
      if (!applied.isSuccess) {
        return ZeniAuthOperationResult.failure(
          applied.message ?? 'Não foi possível preparar esta família.',
        );
      }

      _ref.invalidate(remoteFamilyResolutionProvider);
      _ref.invalidate(remoteFamilySummaryProvider);
      _ref.invalidate(remoteChildrenProvider);
      _ref.invalidate(remoteMissionsProvider);
      _ref.invalidate(remoteRewardsProvider);
      return null;
    } catch (_) {
      return const ZeniAuthOperationResult.failure(
        'Não foi possível preparar esta família agora. Tente novamente.',
      );
    }
  }

  bool _isCurrentSession(ZeniAuthUser user) {
    return _ref.read(authStateProvider).user?.id == user.id &&
        _ref.read(authRepositoryProvider).currentUser?.id == user.id;
  }

  void _recordFamilyPreparation(
    ZeniAuthUser user,
    ZeniAuthOperationResult? result,
  ) {
    if (!_isCurrentSession(user)) return;
    final authState = _ref.read(authStateProvider.notifier);
    if (result?.issue == ZeniAuthIssue.localFamilyConflict) {
      authState.setFamilyIdentityBlocked(user);
    } else if (result == null && ZeniSupabaseBootstrap.state.isAvailable) {
      authState.setFamilyIdentityReady(user);
    }
  }
}

ZeniAuthState _stateFromUser(ZeniAuthUser? user) {
  if (user == null) {
    return const ZeniAuthState.unauthenticated();
  }

  return ZeniAuthState.authenticated(user);
}
