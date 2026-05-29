import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../features/balance/data/models/star_ledger_entry.dart';
import '../../features/family/data/models/child_profile.dart';
import '../../features/family/data/models/family.dart';
import '../../features/family/data/models/family_member.dart';
import '../../features/rewards/data/models/reward.dart';
import '../../features/rewards/data/models/reward_request.dart';
import '../../features/settings/data/models/app_settings.dart';
import '../../features/sync/data/models/device_bootstrap_result.dart';
import '../../features/tasks/data/models/mission.dart';
import '../../features/tasks/data/models/mission_log.dart';
import '../domain/zeni_enums.dart';
import '../security/parent_pin_security.dart';
import 'zeni_app_state.dart';

const _storageKey = 'zeni_app_state_v1';
const _legacyThemeModeKey = 'zeni_theme_mode';
const _legacyDyslexiaFontKey = 'zeni_dyslexia_font';
const _legacyTextScaleKey = 'zeni_text_scale';
const _legacyVibrationKey = 'zeni_vibration';
const _legacyNotificationsKey = 'zeni_notifications';
const _legacyTtsKey = 'zeni_tts';
const _legacyReadAloudByChildProfileKey = 'zeni_read_aloud_by_child_profile';

final zeniAppStateControllerProvider =
    AsyncNotifierProvider<ZeniAppStateController, ZeniAppState>(
      ZeniAppStateController.new,
    );

class ZeniAppStateController extends AsyncNotifier<ZeniAppState> {
  final Uuid _uuid = const Uuid();
  late SharedPreferences _preferences;

  @override
  Future<ZeniAppState> build() async {
    _preferences = await SharedPreferences.getInstance();
    final rawState = _preferences.getString(_storageKey);

    if (rawState == null || rawState.isEmpty) {
      final initialState = _normalizeLoadedState(ZeniAppState.initial());
      await _persist(initialState);
      return initialState;
    }

    final decoded = jsonDecode(rawState) as Map<String, dynamic>;
    final loadedState = ZeniAppState.fromJson(decoded);
    final migratedState = _normalizeLoadedState(loadedState);
    if (rawState != jsonEncode(migratedState.toJson())) {
      await _persist(migratedState);
    }
    return migratedState;
  }

  Future<ChildProfile> createChild({
    required String familyId,
    required String name,
    required String emoji,
    DateTime? birthDate,
  }) async {
    final current = _requireState();
    final now = DateTime.now();
    final childId = _uuid.v4();
    final child = _buildChildProfile(
      childId: childId,
      familyId: familyId,
      name: name,
      emoji: emoji,
      birthDate: birthDate,
      createdAt: now,
    );
    final member = _buildChildFamilyMember(
      familyId: familyId,
      childId: childId,
      name: name,
      createdAt: now,
    );

    final updated = current.copyWith(
      children: [...current.children, child],
      familyMembers: [...current.familyMembers, member],
    );
    await _save(updated);
    return child;
  }

  Future<ChildProfile?> updateChild({
    required String childId,
    required String name,
    required String emoji,
    DateTime? birthDate,
  }) async {
    final current = _requireState();
    final child = current.childById(childId);
    if (child == null) {
      return null;
    }

    final updatedChild = child.copyWith(
      name: name,
      emoji: emoji,
      birthDate: birthDate,
    );
    final updated = current.copyWith(
      children: [
        for (final item in current.children)
          if (item.id == childId) updatedChild else item,
      ],
      familyMembers: [
        for (final member in current.familyMembers)
          if (member.childProfileId == childId)
            member.copyWith(name: name)
          else
            member,
      ],
    );
    await _save(updated);
    return updatedChild;
  }

  Future<void> setChildArchived({
    required String childId,
    required bool isActive,
  }) async {
    final current = _requireState();
    final updated = current.copyWith(
      children: [
        for (final child in current.children)
          if (child.id == childId)
            child.copyWith(isActive: isActive)
          else
            child,
      ],
    );
    await _save(updated);
  }

  Future<Mission> createMission({
    required String familyId,
    required String childId,
    required String title,
    required String description,
    required String emoji,
    required int stars,
    required MissionRecurrence recurrence,
    List<int> customDaysOfWeek = const <int>[],
    required MissionTimeGroup timeGroup,
    required MissionApprovalMode approvalMode,
    required bool requiresPhoto,
  }) async {
    final current = _requireState();
    final now = DateTime.now();
    final mission = _buildMission(
      familyId: familyId,
      childId: childId,
      title: title,
      description: description,
      emoji: emoji,
      stars: stars,
      recurrence: recurrence,
      customDaysOfWeek: customDaysOfWeek,
      timeGroup: timeGroup,
      approvalMode: approvalMode,
      requiresPhoto: requiresPhoto,
      createdAt: now,
      updatedAt: now,
    );
    final updated = current.copyWith(missions: [mission, ...current.missions]);
    await _save(updated);
    return mission;
  }

  Future<Mission?> updateMission({
    required String missionId,
    required String childId,
    required String title,
    required String description,
    required String emoji,
    required int stars,
    required MissionRecurrence recurrence,
    List<int> customDaysOfWeek = const <int>[],
    required MissionTimeGroup timeGroup,
    required MissionApprovalMode approvalMode,
    required bool requiresPhoto,
  }) async {
    final current = _requireState();
    final mission = current.missionById(missionId);
    if (mission == null) {
      return null;
    }

    final updatedMission = mission.copyWith(
      childId: childId,
      title: title,
      description: description,
      emoji: emoji,
      stars: stars,
      recurrence: recurrence,
      customDaysOfWeek: customDaysOfWeek,
      timeGroup: timeGroup,
      approvalMode: approvalMode,
      requiresPhoto: requiresPhoto,
      updatedAt: DateTime.now(),
    );

    final updated = current.copyWith(
      missions: [
        for (final item in current.missions)
          if (item.id == missionId) updatedMission else item,
      ],
    );
    await _save(updated);
    return updatedMission;
  }

  Future<Mission?> archiveMission(String missionId) async {
    final current = _requireState();
    final mission = current.missionById(missionId);
    if (mission == null) {
      return null;
    }

    final archivedMission = mission.copyWith(
      status: MissionStatus.archived,
      updatedAt: DateTime.now(),
    );

    final updated = current.copyWith(
      missions: [
        for (final item in current.missions)
          if (item.id == missionId) archivedMission else item,
      ],
    );
    await _save(updated);
    return archivedMission;
  }

  Future<Mission?> restoreMission(String missionId) async {
    final current = _requireState();
    final mission = current.missionById(missionId);
    if (mission == null) {
      return null;
    }

    final restoredMission = mission.copyWith(
      status: MissionStatus.active,
      updatedAt: DateTime.now(),
    );

    final updated = current.copyWith(
      missions: [
        for (final item in current.missions)
          if (item.id == missionId) restoredMission else item,
      ],
    );
    await _save(updated);
    return restoredMission;
  }

  Future<Reward> createReward({
    required String familyId,
    required String? childId,
    required String title,
    required String description,
    required String emoji,
    required int cost,
    required RewardRenewal renewal,
  }) async {
    final current = _requireState();
    final now = DateTime.now();
    final reward = _buildReward(
      familyId: familyId,
      childId: childId,
      title: title,
      description: description,
      emoji: emoji,
      cost: cost,
      renewal: renewal,
      createdAt: now,
      updatedAt: now,
    );
    final updated = current.copyWith(rewards: [reward, ...current.rewards]);
    await _save(updated);
    return reward;
  }

  Future<void> completeInstitutionalOnboarding() async {
    final current = _requireState();
    final updated = current.copyWith(
      appSettings: _normalizeAppSettings(
        current.appSettings.copyWith(hasCompletedOnboarding: true),
      ),
    );
    await _save(updated);
  }

  Future<DeviceBootstrapApplyResult> applyDeviceBootstrapIfEmpty(
    DeviceBootstrapPayload payload,
  ) async {
    final current = _requireState();
    if (current.hasUserContent) {
      return const DeviceBootstrapApplyResult.failure(
        'Este aparelho já possui dados locais.',
      );
    }

    final parentMembers = current.familyMembers
        .where((member) => member.role == ZeniUserRole.parent)
        .toList();
    final normalizedParentMembers = parentMembers.isEmpty
        ? <FamilyMember>[
            FamilyMember(
              id: 'local-parent',
              familyId: payload.family.id,
              name: 'Responsável',
              role: ZeniUserRole.parent,
              isOwner: true,
              createdAt: payload.family.createdAt,
            ),
          ]
        : [
            for (final member in parentMembers)
              member.copyWith(
                familyId: payload.family.id,
                childProfileId: null,
                isOwner: true,
              ),
          ];

    final childMembers = [
      for (final child in payload.children)
        FamilyMember(
          id: 'member-${child.id}',
          familyId: payload.family.id,
          name: child.name,
          role: ZeniUserRole.child,
          childProfileId: child.id,
          isOwner: false,
          createdAt: child.createdAt,
        ),
    ];

    final updated = current.copyWith(
      family: _normalizeImportedFamily(
        currentFamily: current.family,
        importedFamily: payload.family,
      ),
      children: payload.children,
      familyMembers: [...normalizedParentMembers, ...childMembers],
      missions: payload.missions,
      rewards: payload.rewards,
      appSettings: _normalizeAppSettings(
        current.appSettings.copyWith(hasCompletedOnboarding: true),
      ),
    );
    await _save(updated);
    return const DeviceBootstrapApplyResult.success();
  }

  Future<ChildProfile> completeInitialOnboardingSetup({
    required String childName,
    required String childEmoji,
    required bool hasCompletedOnboarding,
    String? parentPin,
    required bool clearParentPin,
    required bool createSuggestedMission,
    String? missionTitle,
    required bool createSuggestedReward,
    String? rewardTitle,
  }) async {
    final current = _requireState();
    final now = DateTime.now();
    final childId = _uuid.v4();
    final child = _buildChildProfile(
      childId: childId,
      familyId: current.family.id,
      name: childName,
      emoji: childEmoji,
      createdAt: now,
    );
    final member = _buildChildFamilyMember(
      familyId: current.family.id,
      childId: childId,
      name: childName,
      createdAt: now,
    );

    final trimmedMissionTitle = missionTitle?.trim() ?? '';
    final mission = createSuggestedMission && trimmedMissionTitle.isNotEmpty
        ? _buildMission(
            familyId: current.family.id,
            childId: childId,
            title: trimmedMissionTitle,
            description: 'Comece com uma missão simples para criar rotina.',
            emoji: '🛏️',
            stars: 10,
            recurrence: MissionRecurrence.daily,
            timeGroup: MissionTimeGroup.morning,
            approvalMode: MissionApprovalMode.parentApproval,
            requiresPhoto: false,
            createdAt: now,
            updatedAt: now,
          )
        : null;

    final trimmedRewardTitle = rewardTitle?.trim() ?? '';
    final reward = createSuggestedReward && trimmedRewardTitle.isNotEmpty
        ? _buildReward(
            familyId: current.family.id,
            childId: childId,
            title: trimmedRewardTitle,
            description: 'Um mimo simples para celebrar as primeiras estrelas.',
            emoji: '🎬',
            cost: 40,
            renewal: RewardRenewal.weekly,
            createdAt: now,
            updatedAt: now,
          )
        : null;

    final updated = current.copyWith(
      children: [...current.children, child],
      familyMembers: [...current.familyMembers, member],
      missions: mission == null
          ? current.missions
          : [mission, ...current.missions],
      rewards: reward == null ? current.rewards : [reward, ...current.rewards],
      appSettings: _normalizeAppSettings(
        current.appSettings.copyWith(
          hasCompletedOnboarding: hasCompletedOnboarding,
          parentPin: parentPin,
          clearParentPin: clearParentPin,
          parentBiometricsEnabled: false,
        ),
      ),
    );
    await _save(updated);
    return child;
  }

  Future<Reward?> updateReward({
    required String rewardId,
    required String? childId,
    required String title,
    required String description,
    required String emoji,
    required int cost,
    required RewardRenewal renewal,
  }) async {
    final current = _requireState();
    final reward = current.rewardById(rewardId);
    if (reward == null) {
      return null;
    }

    final updatedReward = reward.copyWith(
      childId: childId,
      title: title,
      description: description,
      emoji: emoji,
      cost: cost,
      renewal: renewal,
      updatedAt: DateTime.now(),
    );

    final updated = current.copyWith(
      rewards: [
        for (final item in current.rewards)
          if (item.id == rewardId) updatedReward else item,
      ],
    );
    await _save(updated);
    return updatedReward;
  }

  Future<Reward?> archiveReward(String rewardId) async {
    final current = _requireState();
    final reward = current.rewardById(rewardId);
    if (reward == null) {
      return null;
    }

    final archivedReward = reward.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );

    final updated = current.copyWith(
      rewards: [
        for (final item in current.rewards)
          if (item.id == rewardId) archivedReward else item,
      ],
    );
    await _save(updated);
    return archivedReward;
  }

  Future<Reward?> restoreReward(String rewardId) async {
    final current = _requireState();
    final reward = current.rewardById(rewardId);
    if (reward == null) {
      return null;
    }

    final restoredReward = reward.copyWith(
      isActive: true,
      updatedAt: DateTime.now(),
    );

    final updated = current.copyWith(
      rewards: [
        for (final item in current.rewards)
          if (item.id == rewardId) restoredReward else item,
      ],
    );
    await _save(updated);
    return restoredReward;
  }

  Future<void> submitMission({
    required String childId,
    required Mission mission,
    required MissionLog? currentLog,
    String? note,
  }) async {
    final current = _requireState();
    final child = current.childById(childId);
    if (child == null) {
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final autoApprove = mission.approvalMode == MissionApprovalMode.automatic;
    final existingApprovedLog = current.missionLogs
        .where(
          (item) =>
              item.childId == childId &&
              item.missionId == mission.id &&
              item.status == MissionLogStatus.approved &&
              item.scheduledDate.year == today.year &&
              item.scheduledDate.month == today.month &&
              item.scheduledDate.day == today.day,
        )
        .firstOrNull;
    if (autoApprove &&
        ((currentLog?.status == MissionLogStatus.approved) ||
            existingApprovedLog != null)) {
      return;
    }

    final log =
        currentLog ??
        MissionLog(
          id: _uuid.v4(),
          missionId: mission.id,
          childId: childId,
          scheduledDate: today,
          status: MissionLogStatus.pending,
          starsAwarded: mission.stars,
        );

    final updatedLog = MissionLog(
      id: log.id,
      missionId: log.missionId,
      childId: log.childId,
      scheduledDate: log.scheduledDate,
      status: autoApprove
          ? MissionLogStatus.approved
          : MissionLogStatus.awaitingApproval,
      starsAwarded: mission.stars,
      completedAt: now,
      approvedAt: autoApprove ? now : null,
      photoUrl: log.photoUrl,
      note: note ?? log.note,
    );

    var updatedChildren = current.children;
    var updatedLedger = current.starLedgerEntries;

    if (autoApprove) {
      final newBalance = child.starBalance + mission.stars;
      updatedChildren = [
        for (final item in current.children)
          if (item.id == childId)
            item.copyWith(
              starBalance: newBalance,
              streakCount: item.streakCount + 1,
            )
          else
            item,
      ];
      updatedLedger = [
        StarLedgerEntry(
          id: _uuid.v4(),
          familyId: current.family.id,
          childId: childId,
          amount: mission.stars,
          balanceAfter: newBalance,
          type: StarLedgerEntryType.earned,
          title: mission.title,
          description: note ?? 'Missão concluída.',
          createdAt: now,
          relatedMissionLogId: updatedLog.id,
        ),
        ...current.starLedgerEntries,
      ];
    }

    final updated = current.copyWith(
      children: updatedChildren,
      missionLogs: _upsertMissionLog(current.missionLogs, updatedLog),
      starLedgerEntries: updatedLedger,
    );
    await _save(updated);
  }

  Future<void> cancelMissionSubmission({
    required String missionId,
    required String childId,
  }) async {
    final current = _requireState();
    final updated = current.copyWith(
      missionLogs: [
        for (final log in current.missionLogs)
          if (log.missionId == missionId &&
              log.childId == childId &&
              log.status == MissionLogStatus.awaitingApproval)
            MissionLog(
              id: log.id,
              missionId: log.missionId,
              childId: log.childId,
              scheduledDate: log.scheduledDate,
              status: MissionLogStatus.pending,
              starsAwarded: log.starsAwarded,
            )
          else
            log,
      ],
    );
    await _save(updated);
  }

  Future<void> approveMissionLog(String logId) async {
    final current = _requireState();
    final log = current.missionLogs
        .where((item) => item.id == logId)
        .firstOrNull;
    if (log == null) {
      return;
    }
    if (log.status != MissionLogStatus.awaitingApproval) {
      return;
    }

    final child = current.childById(log.childId);
    final mission = current.missionById(log.missionId);
    if (child == null) {
      return;
    }

    final now = DateTime.now();
    final newBalance = child.starBalance + log.starsAwarded;
    final approvedLog = MissionLog(
      id: log.id,
      missionId: log.missionId,
      childId: log.childId,
      scheduledDate: log.scheduledDate,
      status: MissionLogStatus.approved,
      starsAwarded: log.starsAwarded,
      completedAt: log.completedAt ?? now,
      approvedAt: now,
      photoUrl: log.photoUrl,
      note: log.note,
    );

    final updated = current.copyWith(
      children: [
        for (final item in current.children)
          if (item.id == child.id)
            item.copyWith(
              starBalance: newBalance,
              streakCount: item.streakCount + 1,
            )
          else
            item,
      ],
      missionLogs: _upsertMissionLog(current.missionLogs, approvedLog),
      starLedgerEntries: [
        StarLedgerEntry(
          id: _uuid.v4(),
          familyId: current.family.id,
          childId: child.id,
          amount: log.starsAwarded,
          balanceAfter: newBalance,
          type: StarLedgerEntryType.earned,
          title: mission?.title ?? 'Missão aprovada',
          description: 'Missão aprovada pelo responsável.',
          createdAt: now,
          relatedMissionLogId: approvedLog.id,
        ),
        ...current.starLedgerEntries,
      ],
    );
    await _save(updated);
  }

  Future<void> rejectMissionLog(String logId) async {
    final current = _requireState();
    final log = current.missionLogs
        .where((item) => item.id == logId)
        .firstOrNull;
    if (log == null || log.status != MissionLogStatus.awaitingApproval) {
      return;
    }

    final now = DateTime.now();
    final updated = current.copyWith(
      missionLogs: [
        for (final item in current.missionLogs)
          if (item.id == logId)
            MissionLog(
              id: item.id,
              missionId: item.missionId,
              childId: item.childId,
              scheduledDate: item.scheduledDate,
              status: MissionLogStatus.rejected,
              starsAwarded: item.starsAwarded,
              completedAt: item.completedAt,
              rejectedAt: now,
              photoUrl: item.photoUrl,
              note: item.note,
            )
          else
            item,
      ],
    );
    await _save(updated);
  }

  Future<void> requestReward({
    required String childId,
    required Reward reward,
  }) async {
    final current = _requireState();
    final child = current.childById(childId);
    if (child == null || child.starBalance < reward.cost) {
      return;
    }

    final now = DateTime.now();
    final newBalance = child.starBalance - reward.cost;
    final request = RewardRequest(
      id: _uuid.v4(),
      rewardId: reward.id,
      childId: childId,
      status: RewardRequestStatus.pending,
      requestedAt: now,
    );

    final updated = current.copyWith(
      children: [
        for (final item in current.children)
          if (item.id == childId)
            item.copyWith(starBalance: newBalance)
          else
            item,
      ],
      rewardRequests: [request, ...current.rewardRequests],
      starLedgerEntries: [
        StarLedgerEntry(
          id: _uuid.v4(),
          familyId: current.family.id,
          childId: childId,
          amount: -reward.cost,
          balanceAfter: newBalance,
          type: StarLedgerEntryType.spent,
          title: reward.title,
          description: 'Mimo solicitado.',
          createdAt: now,
          relatedRewardRequestId: request.id,
        ),
        ...current.starLedgerEntries,
      ],
    );
    await _save(updated);
  }

  Future<void> approveRewardRequest(String requestId) async {
    await _resolveRewardRequest(
      requestId: requestId,
      status: RewardRequestStatus.approved,
    );
  }

  Future<void> rejectRewardRequest(String requestId) async {
    final current = _requireState();
    final request = current.rewardRequests
        .where((item) => item.id == requestId)
        .firstOrNull;
    if (request == null || request.status != RewardRequestStatus.pending) {
      return;
    }

    final child = current.childById(request.childId);
    final reward = current.rewardById(request.rewardId);
    if (child == null || reward == null) {
      return;
    }

    final now = DateTime.now();
    final newBalance = child.starBalance + reward.cost;
    final updated = current.copyWith(
      children: [
        for (final item in current.children)
          if (item.id == child.id)
            item.copyWith(starBalance: newBalance)
          else
            item,
      ],
      rewardRequests: [
        for (final item in current.rewardRequests)
          if (item.id == requestId)
            item.copyWith(status: RewardRequestStatus.rejected, resolvedAt: now)
          else
            item,
      ],
      starLedgerEntries: [
        StarLedgerEntry(
          id: _uuid.v4(),
          familyId: current.family.id,
          childId: child.id,
          amount: reward.cost,
          balanceAfter: newBalance,
          type: StarLedgerEntryType.refunded,
          title: 'Reembolso: ${reward.title}',
          description: 'Pedido de mimo rejeitado pelo responsável.',
          createdAt: now,
          relatedRewardRequestId: request.id,
        ),
        ...current.starLedgerEntries,
      ],
    );
    await _save(updated);
  }

  Future<void> updateAppSettings(AppSettings settings) async {
    final current = _requireState();
    await _save(current.copyWith(appSettings: _normalizeAppSettings(settings)));
  }

  ZeniAppState _requireState() {
    final current = state.asData?.value;
    if (current == null) {
      throw StateError('Zeni app state is not loaded yet.');
    }

    return current;
  }

  Future<void> _resolveRewardRequest({
    required String requestId,
    required RewardRequestStatus status,
  }) async {
    final current = _requireState();
    final request = current.rewardRequests
        .where((item) => item.id == requestId)
        .firstOrNull;
    if (request == null || request.status != RewardRequestStatus.pending) {
      return;
    }
    final now = DateTime.now();
    final updated = current.copyWith(
      rewardRequests: [
        for (final item in current.rewardRequests)
          if (item.id == requestId)
            item.copyWith(status: status, resolvedAt: now)
          else
            item,
      ],
    );
    await _save(updated);
  }

  List<MissionLog> _upsertMissionLog(
    List<MissionLog> logs,
    MissionLog updatedLog,
  ) {
    final exists = logs.any((log) => log.id == updatedLog.id);
    if (!exists) {
      return [updatedLog, ...logs];
    }

    return [
      for (final log in logs)
        if (log.id == updatedLog.id) updatedLog else log,
    ];
  }

  Future<void> _save(ZeniAppState newState) async {
    state = AsyncData(newState);
    await _persist(newState);
  }

  Future<void> _persist(ZeniAppState appState) async {
    await _preferences.setString(_storageKey, jsonEncode(appState.toJson()));
  }

  ChildProfile _buildChildProfile({
    required String childId,
    required String familyId,
    required String name,
    required String emoji,
    DateTime? birthDate,
    required DateTime createdAt,
  }) {
    return ChildProfile(
      id: childId,
      familyId: familyId,
      name: name,
      emoji: emoji,
      birthDate: birthDate,
      starBalance: 0,
      streakCount: 0,
      createdAt: createdAt,
    );
  }

  FamilyMember _buildChildFamilyMember({
    required String familyId,
    required String childId,
    required String name,
    required DateTime createdAt,
  }) {
    return FamilyMember(
      id: _uuid.v4(),
      familyId: familyId,
      name: name,
      role: ZeniUserRole.child,
      childProfileId: childId,
      createdAt: createdAt,
    );
  }

  Mission _buildMission({
    required String familyId,
    required String childId,
    required String title,
    required String description,
    required String emoji,
    required int stars,
    required MissionRecurrence recurrence,
    List<int> customDaysOfWeek = const <int>[],
    required MissionTimeGroup timeGroup,
    required MissionApprovalMode approvalMode,
    required bool requiresPhoto,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return Mission(
      id: _uuid.v4(),
      familyId: familyId,
      childId: childId,
      title: title,
      description: description,
      emoji: emoji,
      stars: stars,
      recurrence: recurrence,
      customDaysOfWeek: customDaysOfWeek,
      timeGroup: timeGroup,
      approvalMode: approvalMode,
      status: MissionStatus.active,
      createdAt: createdAt,
      updatedAt: updatedAt,
      requiresPhoto: requiresPhoto,
    );
  }

  Reward _buildReward({
    required String familyId,
    required String? childId,
    required String title,
    required String description,
    required String emoji,
    required int cost,
    required RewardRenewal renewal,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return Reward(
      id: _uuid.v4(),
      familyId: familyId,
      childId: childId,
      title: title,
      description: description,
      emoji: emoji,
      cost: cost,
      renewal: renewal,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Family _normalizeImportedFamily({
    required Family currentFamily,
    required Family importedFamily,
  }) {
    return importedFamily.copyWith(
      inviteCode: currentFamily.inviteCode,
      createdAt: importedFamily.createdAt,
    );
  }

  ZeniAppState _normalizeLoadedState(ZeniAppState state) {
    return _migrateLegacyAccessibilitySettings(
      state.copyWith(appSettings: _normalizeAppSettings(state.appSettings)),
    );
  }

  AppSettings _normalizeAppSettings(AppSettings settings) {
    final legacyPin = settings.parentPin;
    if ((legacyPin ?? '').length == 4) {
      final credentials = ParentPinSecurity.createCredentials(legacyPin!);
      return settings.copyWith(
        clearParentPin: true,
        parentPinHash: credentials.hash,
        parentPinSalt: credentials.salt,
      );
    }

    if (!settings.hasParentPin) {
      return settings.copyWith(clearParentPin: true);
    }

    return settings;
  }

  ZeniAppState _migrateLegacyAccessibilitySettings(ZeniAppState state) {
    final keys = _preferences.getKeys();
    final current = state.appSettings;
    const defaults = AppSettings();

    var migrated = current;

    if (current.themeMode == defaults.themeMode &&
        keys.contains(_legacyThemeModeKey)) {
      migrated = migrated.copyWith(
        themeMode:
            _preferences.getString(_legacyThemeModeKey) ?? defaults.themeMode,
      );
    }

    if (current.dyslexiaFontEnabled == defaults.dyslexiaFontEnabled &&
        keys.contains(_legacyDyslexiaFontKey)) {
      migrated = migrated.copyWith(
        dyslexiaFontEnabled:
            _preferences.getBool(_legacyDyslexiaFontKey) ??
            defaults.dyslexiaFontEnabled,
      );
    }

    if (current.textScale == defaults.textScale &&
        keys.contains(_legacyTextScaleKey)) {
      migrated = migrated.copyWith(
        textScale:
            _preferences.getDouble(_legacyTextScaleKey) ?? defaults.textScale,
      );
    }

    if (current.vibrationEnabled == defaults.vibrationEnabled &&
        keys.contains(_legacyVibrationKey)) {
      migrated = migrated.copyWith(
        vibrationEnabled:
            _preferences.getBool(_legacyVibrationKey) ??
            defaults.vibrationEnabled,
      );
    }

    if (current.notificationsEnabled == defaults.notificationsEnabled &&
        keys.contains(_legacyNotificationsKey)) {
      migrated = migrated.copyWith(
        notificationsEnabled:
            _preferences.getBool(_legacyNotificationsKey) ??
            defaults.notificationsEnabled,
      );
    }

    if (current.ttsEnabled == defaults.ttsEnabled &&
        keys.contains(_legacyTtsKey)) {
      migrated = migrated.copyWith(
        ttsEnabled: _preferences.getBool(_legacyTtsKey) ?? defaults.ttsEnabled,
      );
    }

    if (current.readAloudByChildProfile == defaults.readAloudByChildProfile &&
        keys.contains(_legacyReadAloudByChildProfileKey)) {
      migrated = migrated.copyWith(
        readAloudByChildProfile:
            _preferences.getBool(_legacyReadAloudByChildProfileKey) ??
            defaults.readAloudByChildProfile,
      );
    }

    return state.copyWith(appSettings: migrated);
  }
}
