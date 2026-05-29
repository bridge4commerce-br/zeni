import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/core/mock/zeni_mock_data.dart';
import 'package:zeni/core/providers/zeni_repository_providers.dart';
import 'package:zeni/core/state/zeni_app_state.dart';
import 'package:zeni/core/state/zeni_app_state_controller.dart';
import 'package:zeni/features/balance/data/repositories/balance_repository.dart';
import 'package:zeni/features/balance/data/repositories/mock_balance_repository.dart';
import 'package:zeni/features/family/data/repositories/family_repository.dart';
import 'package:zeni/features/family/data/repositories/mock_family_repository.dart';
import 'package:zeni/features/rewards/data/repositories/mock_reward_repository.dart';
import 'package:zeni/features/rewards/data/repositories/reward_repository.dart';
import 'package:zeni/features/settings/data/models/app_settings.dart';
import 'package:zeni/features/tasks/data/repositories/mission_repository.dart';
import 'package:zeni/features/tasks/data/repositories/mock_mission_repository.dart';
import 'package:zeni/features/tasks/data/models/mission_log.dart';

void main() {
  void seedMockAppState() {
    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(ZeniAppState.seeded().toJson()),
    });
  }

  test('mock data has base family, children, missions and rewards', () {
    expect(ZeniMockData.family.name, isNotEmpty);
    expect(ZeniMockData.children, isNotEmpty);
    expect(ZeniMockData.missions, isNotEmpty);
    expect(ZeniMockData.rewards, isNotEmpty);
  });

  test('abstract repository providers resolve to the local implementation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(familyRepositoryProvider), isA<FamilyRepository>());
    expect(
      container.read(familyRepositoryProvider),
      isA<MockFamilyRepository>(),
    );
    expect(container.read(missionRepositoryProvider), isA<MissionRepository>());
    expect(
      container.read(missionRepositoryProvider),
      isA<MockMissionRepository>(),
    );
    expect(container.read(rewardRepositoryProvider), isA<RewardRepository>());
    expect(
      container.read(rewardRepositoryProvider),
      isA<MockRewardRepository>(),
    );
    expect(container.read(balanceRepositoryProvider), isA<BalanceRepository>());
    expect(
      container.read(balanceRepositoryProvider),
      isA<MockBalanceRepository>(),
    );
  });

  test('mock repositories return child data', () async {
    seedMockAppState();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final familyRepository = container.read(familyRepositoryProvider);
    final missionRepository = container.read(missionRepositoryProvider);
    final rewardRepository = container.read(rewardRepositoryProvider);
    final balanceRepository = container.read(balanceRepositoryProvider);

    final children = await familyRepository.getChildren();
    final child = children.first;

    final missions = await missionRepository.getMissionsForChild(child.id);
    final rewards = await rewardRepository.getRewardsForChild(child.id);
    final ledger = await balanceRepository.getLedgerForChild(child.id);

    expect(missions, isNotEmpty);
    expect(rewards, isNotEmpty);
    expect(ledger, isNotEmpty);
  });

  test(
    'manual repository creation of mission and reward still persists',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final familyRepository = container.read(familyRepositoryProvider);
      final missionRepository = container.read(missionRepositoryProvider);
      final rewardRepository = container.read(rewardRepositoryProvider);
      await container.read(zeniAppStateControllerProvider.future);

      final child = await familyRepository.createChild(
        familyId: 'local-family',
        name: 'Luna',
        emoji: '🦊',
      );

      final mission = await missionRepository.createMission(
        familyId: 'local-family',
        childId: child.id,
        title: 'Arrumar a cama',
        description: 'Rotina da manhã',
        emoji: '🛏️',
        stars: 10,
        recurrence: MissionRecurrence.daily,
        timeGroup: MissionTimeGroup.morning,
        approvalMode: MissionApprovalMode.parentApproval,
        requiresPhoto: false,
      );

      final reward = await rewardRepository.createReward(
        familyId: 'local-family',
        childId: child.id,
        title: 'Escolher o filme',
        description: 'Mimo da semana',
        emoji: '🎬',
        cost: 40,
        renewal: RewardRenewal.weekly,
      );

      final state = container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value;

      expect(state.children.single.id, child.id);
      expect(state.missions.single.id, mission.id);
      expect(state.rewards.single.id, reward.id);
    },
  );

  test(
    'onboarding setup persists child, mission and reward atomically',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(zeniAppStateControllerProvider.future);

      final child = await container
          .read(zeniAppStateControllerProvider.notifier)
          .completeInitialOnboardingSetup(
            childName: 'Luna',
            childEmoji: '🦊',
            hasCompletedOnboarding: true,
            clearParentPin: true,
            createSuggestedMission: true,
            missionTitle: 'Arrumar a cama',
            createSuggestedReward: true,
            rewardTitle: 'Escolher o filme',
          );

      final state = container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value;
      final mission = state.missions.single;
      final reward = state.rewards.single;
      final preferences = await SharedPreferences.getInstance();
      final persistedState =
          jsonDecode(preferences.getString('zeni_app_state_v1')!)
              as Map<String, dynamic>;

      expect(state.appSettings.hasCompletedOnboarding, isTrue);
      expect(state.children, hasLength(1));
      expect(state.children.single.name, 'Luna');
      expect(mission.childId, child.id);
      expect(mission.isActive, isTrue);
      expect(mission.occursOnDate(DateTime.now()), isTrue);
      expect(reward.childId, child.id);
      expect(reward.isActive, isTrue);
      expect((persistedState['children'] as List<dynamic>), hasLength(1));
      expect((persistedState['missions'] as List<dynamic>), hasLength(1));
      expect((persistedState['rewards'] as List<dynamic>), hasLength(1));
    },
  );

  test('updating mission persists in the shared local store', () async {
    seedMockAppState();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final missionRepository = container.read(missionRepositoryProvider);

    final initialMissions = await missionRepository.getMissionsForChild(
      'child-1',
    );
    final mission = initialMissions.first;

    final updatedMission = await missionRepository.updateMission(
      missionId: mission.id,
      childId: 'child-2',
      title: 'Nova missão editada',
      description: 'Descrição atualizada',
      emoji: '🚀',
      stars: 25,
      recurrence: MissionRecurrence.weekends,
      timeGroup: MissionTimeGroup.evening,
      approvalMode: MissionApprovalMode.automatic,
      requiresPhoto: true,
    );

    final childOneMissions = await missionRepository.getMissionsForChild(
      'child-1',
    );
    final childTwoMissions = await missionRepository.getMissionsForChild(
      'child-2',
    );

    expect(updatedMission, isNotNull);
    expect(updatedMission!.title, 'Nova missão editada');
    expect(updatedMission.childId, 'child-2');
    expect(updatedMission.emoji, '🚀');
    expect(childOneMissions.any((item) => item.id == mission.id), isFalse);
    expect(
      childTwoMissions.any((item) {
        return item.id == mission.id &&
            item.title == 'Nova missão editada' &&
            item.emoji == '🚀';
      }),
      isTrue,
    );
  });

  test('updating reward persists in the shared local store', () async {
    seedMockAppState();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final rewardRepository = container.read(rewardRepositoryProvider);

    final initialRewards = await rewardRepository.getRewardsForChild('child-1');
    final reward = initialRewards.first;

    final updatedReward = await rewardRepository.updateReward(
      rewardId: reward.id,
      childId: 'child-2',
      title: 'Novo mimo editado',
      description: 'Descrição do mimo atualizada',
      emoji: '🦄',
      cost: 95,
      renewal: RewardRenewal.monthly,
    );

    final childOneRewards = await rewardRepository.getRewardsForChild(
      'child-1',
    );
    final childTwoRewards = await rewardRepository.getRewardsForChild(
      'child-2',
    );

    expect(updatedReward, isNotNull);
    expect(updatedReward!.title, 'Novo mimo editado');
    expect(updatedReward.childId, 'child-2');
    expect(updatedReward.emoji, '🦄');
    expect(childOneRewards.any((item) => item.id == reward.id), isFalse);
    expect(
      childTwoRewards.any((item) {
        return item.id == reward.id &&
            item.title == 'Novo mimo editado' &&
            item.emoji == '🦄';
      }),
      isTrue,
    );
  });

  test(
    'archiving mission hides it from active parent and child lists',
    () async {
      seedMockAppState();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final missionRepository = container.read(missionRepositoryProvider);

      final childMissionsBefore = await missionRepository.getMissionsForChild(
        'child-1',
      );
      final mission = childMissionsBefore.first;

      final archivedMission = await missionRepository.archiveMission(
        mission.id,
      );
      final childMissionsAfter = await missionRepository.getMissionsForChild(
        'child-1',
      );
      final familyMissionsAfter = await missionRepository.getMissionsForFamily(
        'family-1',
      );

      expect(archivedMission, isNotNull);
      expect(archivedMission!.status, MissionStatus.archived);
      expect(childMissionsAfter.any((item) => item.id == mission.id), isFalse);
      expect(familyMissionsAfter.any((item) => item.id == mission.id), isFalse);
    },
  );

  test(
    'restoring mission returns it to active parent and child lists',
    () async {
      seedMockAppState();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final missionRepository = container.read(missionRepositoryProvider);

      final mission = (await missionRepository.getMissionsForChild(
        'child-1',
      )).first;

      await missionRepository.archiveMission(mission.id);
      final restoredMission = await missionRepository.restoreMission(
        mission.id,
      );

      final childMissionsAfter = await missionRepository.getMissionsForChild(
        'child-1',
      );
      final familyMissionsAfter = await missionRepository.getMissionsForFamily(
        'family-1',
      );

      expect(restoredMission, isNotNull);
      expect(restoredMission!.status, MissionStatus.active);
      expect(childMissionsAfter.any((item) => item.id == mission.id), isTrue);
      expect(familyMissionsAfter.any((item) => item.id == mission.id), isTrue);
    },
  );

  test(
    'archiving reward hides it from active parent and child lists',
    () async {
      seedMockAppState();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final rewardRepository = container.read(rewardRepositoryProvider);

      final reward = (await rewardRepository.getRewardsForChild(
        'child-1',
      )).first;

      final archivedReward = await rewardRepository.archiveReward(reward.id);
      final childRewardsAfter = await rewardRepository.getRewardsForChild(
        'child-1',
      );
      final familyRewardsAfter = await rewardRepository.getRewardsForFamily(
        'family-1',
      );

      expect(archivedReward, isNotNull);
      expect(archivedReward!.isActive, isFalse);
      expect(childRewardsAfter.any((item) => item.id == reward.id), isFalse);
      expect(familyRewardsAfter.any((item) => item.id == reward.id), isFalse);
    },
  );

  test(
    'restoring reward returns it to active parent and child lists',
    () async {
      seedMockAppState();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final rewardRepository = container.read(rewardRepositoryProvider);

      final reward = (await rewardRepository.getRewardsForChild(
        'child-1',
      )).first;

      await rewardRepository.archiveReward(reward.id);
      final restoredReward = await rewardRepository.restoreReward(reward.id);

      final childRewardsAfter = await rewardRepository.getRewardsForChild(
        'child-1',
      );
      final familyRewardsAfter = await rewardRepository.getRewardsForFamily(
        'family-1',
      );

      expect(restoredReward, isNotNull);
      expect(restoredReward!.isActive, isTrue);
      expect(childRewardsAfter.any((item) => item.id == reward.id), isTrue);
      expect(familyRewardsAfter.any((item) => item.id == reward.id), isTrue);
    },
  );

  test('parent security settings persist in the local store', () async {
    seedMockAppState();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(zeniAppStateControllerProvider.future);
    await container
        .read(zeniAppStateControllerProvider.notifier)
        .updateAppSettings(
          const AppSettings(parentPin: '2468', parentBiometricsEnabled: true),
        );

    final persistedSettings = container
        .read(zeniAppStateControllerProvider)
        .asData!
        .value
        .appSettings;
    final sharedPreferences = await SharedPreferences.getInstance();
    final persistedState =
        jsonDecode(sharedPreferences.getString('zeni_app_state_v1')!)
            as Map<String, dynamic>;
    final persistedJsonSettings =
        persistedState['appSettings'] as Map<String, dynamic>;

    expect(persistedSettings.parentPin, isNull);
    expect(persistedSettings.parentPinHash, isNotNull);
    expect(persistedSettings.parentPinSalt, isNotNull);
    expect(persistedSettings.matchesParentPin('2468'), isTrue);
    expect(persistedSettings.hasParentPin, isTrue);
    expect(persistedSettings.parentBiometricsEnabled, isTrue);
    expect(persistedJsonSettings.containsKey('parentPin'), isFalse);
    expect(persistedJsonSettings['parentPinHash'], isNotNull);
    expect(persistedJsonSettings['parentPinSalt'], isNotNull);
  });

  test(
    'parent PIN rejects incorrect values and tolerates no PIN configured',
    () {
      const withoutPin = AppSettings();
      const withLegacyPin = AppSettings(parentPin: '2468');

      expect(withoutPin.hasParentPin, isFalse);
      expect(withoutPin.matchesParentPin('2468'), isFalse);
      expect(withLegacyPin.matchesParentPin('0000'), isFalse);
    },
  );

  test('legacy plain parent PIN migrates to hash on load', () async {
    final seeded = ZeniAppState.seeded().toJson();
    final appSettings =
        Map<String, dynamic>.from(seeded['appSettings'] as Map<String, dynamic>)
          ..['parentPin'] = '2468'
          ..['parentBiometricsEnabled'] = true;

    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode({...seeded, 'appSettings': appSettings}),
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(zeniAppStateControllerProvider.future);
    final migratedSettings = state.appSettings;
    final sharedPreferences = await SharedPreferences.getInstance();
    final persistedState =
        jsonDecode(sharedPreferences.getString('zeni_app_state_v1')!)
            as Map<String, dynamic>;
    final persistedJsonSettings =
        persistedState['appSettings'] as Map<String, dynamic>;

    expect(migratedSettings.parentPin, isNull);
    expect(migratedSettings.parentPinHash, isNotNull);
    expect(migratedSettings.parentPinSalt, isNotNull);
    expect(migratedSettings.matchesParentPin('2468'), isTrue);
    expect(migratedSettings.matchesParentPin('0000'), isFalse);
    expect(persistedJsonSettings.containsKey('parentPin'), isFalse);
    expect(persistedJsonSettings['parentPinHash'], isNotNull);
    expect(persistedJsonSettings['parentPinSalt'], isNotNull);
  });

  test('legacy accessibility preferences migrate into app settings', () async {
    SharedPreferences.setMockInitialValues({
      'zeni_theme_mode': 'dark',
      'zeni_dyslexia_font': true,
      'zeni_text_scale': 1.2,
      'zeni_vibration': false,
      'zeni_notifications': false,
      'zeni_tts': true,
      'zeni_read_aloud_by_child_profile': true,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(zeniAppStateControllerProvider.future);

    expect(state.appSettings.themeMode, 'dark');
    expect(state.appSettings.dyslexiaFontEnabled, isTrue);
    expect(state.appSettings.textScale, 1.2);
    expect(state.appSettings.vibrationEnabled, isFalse);
    expect(state.appSettings.notificationsEnabled, isFalse);
    expect(state.appSettings.ttsEnabled, isTrue);
    expect(state.appSettings.readAloudByChildProfile, isTrue);
  });

  test(
    'manual approval submission does not change streak or ledger before approval',
    () async {
      seedMockAppState();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final missionRepository = container.read(missionRepositoryProvider);
      await container.read(zeniAppStateControllerProvider.future);

      final initialState = container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value;
      final mission = initialState.missionById('mission-1')!;
      final childBefore = initialState.childById('child-1')!;
      final ledgerCountBefore = initialState.starLedgerEntries.length;
      final currentLog = initialState.missionLogs
          .where(
            (log) => log.missionId == mission.id && log.childId == 'child-1',
          )
          .firstOrNull;

      await missionRepository.submitMission(
        childId: 'child-1',
        mission: mission,
        currentLog: currentLog,
        note: 'Concluída para revisão',
      );

      final updatedState = container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value;
      final childAfter = updatedState.childById('child-1')!;
      final updatedLog = updatedState.missionLogs
          .where((log) => log.id == currentLog!.id)
          .first;

      expect(updatedLog.status, MissionLogStatus.awaitingApproval);
      expect(childAfter.streakCount, childBefore.streakCount);
      expect(childAfter.starBalance, childBefore.starBalance);
      expect(updatedState.starLedgerEntries.length, ledgerCountBefore);
    },
  );

  test('approving manual mission applies streak and ledger once', () async {
    seedMockAppState();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final missionRepository = container.read(missionRepositoryProvider);
    await container.read(zeniAppStateControllerProvider.future);

    final initialState = container
        .read(zeniAppStateControllerProvider)
        .asData!
        .value;
    final mission = initialState.missionById('mission-1')!;
    final childBefore = initialState.childById('child-1')!;
    final currentLog = initialState.missionLogs
        .where((log) => log.missionId == mission.id && log.childId == 'child-1')
        .firstOrNull;

    await missionRepository.submitMission(
      childId: 'child-1',
      mission: mission,
      currentLog: currentLog,
    );

    await missionRepository.approveMissionLog(currentLog!.id);
    await missionRepository.approveMissionLog(currentLog.id);

    final updatedState = container
        .read(zeniAppStateControllerProvider)
        .asData!
        .value;
    final childAfter = updatedState.childById('child-1')!;
    final approvedLog = updatedState.missionLogs
        .where((log) => log.id == currentLog.id)
        .first;
    final earnedEntries = updatedState.starLedgerEntries
        .where((entry) => entry.relatedMissionLogId == currentLog.id)
        .toList();

    expect(approvedLog.status, MissionLogStatus.approved);
    expect(childAfter.streakCount, childBefore.streakCount + 1);
    expect(childAfter.starBalance, childBefore.starBalance + mission.stars);
    expect(earnedEntries.length, 1);
  });

  test('auto-approved mission does not credit twice on repeated submit', () async {
    seedMockAppState();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final missionRepository = container.read(missionRepositoryProvider);
    await container.read(zeniAppStateControllerProvider.future);

    final initialState = container
        .read(zeniAppStateControllerProvider)
        .asData!
        .value;
    final mission = initialState.missionById('mission-2')!;
    final childBefore = initialState.childById('child-1')!;
    final currentLog = initialState.missionLogs
        .where((log) => log.missionId == mission.id && log.childId == 'child-1')
        .first;
    final ledgerCountBefore = initialState.starLedgerEntries.length;

    await missionRepository.submitMission(
      childId: 'child-1',
      mission: mission,
      currentLog: currentLog,
    );

    final updatedState = container
        .read(zeniAppStateControllerProvider)
        .asData!
        .value;
    final childAfter = updatedState.childById('child-1')!;

    expect(childAfter.starBalance, childBefore.starBalance);
    expect(updatedState.starLedgerEntries.length, ledgerCountBefore);
  });

  test(
    'rejecting manual mission does not change streak, balance or ledger',
    () async {
      seedMockAppState();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final missionRepository = container.read(missionRepositoryProvider);
      await container.read(zeniAppStateControllerProvider.future);

      final initialState = container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value;
      final mission = initialState.missionById('mission-1')!;
      final childBefore = initialState.childById('child-1')!;
      final ledgerCountBefore = initialState.starLedgerEntries.length;
      final currentLog = initialState.missionLogs
          .where(
            (log) => log.missionId == mission.id && log.childId == 'child-1',
          )
          .firstOrNull;

      await missionRepository.submitMission(
        childId: 'child-1',
        mission: mission,
        currentLog: currentLog,
      );
      await missionRepository.rejectMissionLog(currentLog!.id);

      final updatedState = container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value;
      final childAfter = updatedState.childById('child-1')!;
      final rejectedLog = updatedState.missionLogs
          .where((log) => log.id == currentLog.id)
          .first;

      expect(rejectedLog.status, MissionLogStatus.rejected);
      expect(childAfter.streakCount, childBefore.streakCount);
      expect(childAfter.starBalance, childBefore.starBalance);
    expect(updatedState.starLedgerEntries.length, ledgerCountBefore);
  },
  );

  test('approving reward request does not debit stars again', () async {
    seedMockAppState();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final rewardRepository = container.read(rewardRepositoryProvider);
    await container.read(zeniAppStateControllerProvider.future);

    final initialState = container
        .read(zeniAppStateControllerProvider)
        .asData!
        .value;
    final request = initialState.rewardRequests.first;
    final childBefore = initialState.childById(request.childId)!;
    final ledgerCountBefore = initialState.starLedgerEntries.length;

    await rewardRepository.approveRewardRequest(request.id);

    final updatedState = container
        .read(zeniAppStateControllerProvider)
        .asData!
        .value;
    final childAfter = updatedState.childById(request.childId)!;
    final updatedRequest = updatedState.rewardRequests
        .where((item) => item.id == request.id)
        .first;

    expect(updatedRequest.status, RewardRequestStatus.approved);
    expect(childAfter.starBalance, childBefore.starBalance);
    expect(updatedState.starLedgerEntries.length, ledgerCountBefore);
  });

  test('rejecting the same reward request twice does not refund twice', () async {
    seedMockAppState();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final rewardRepository = container.read(rewardRepositoryProvider);
    await container.read(zeniAppStateControllerProvider.future);

    final initialState = container
        .read(zeniAppStateControllerProvider)
        .asData!
        .value;
    final request = initialState.rewardRequests.first;
    final reward = initialState.rewardById(request.rewardId)!;
    final childBefore = initialState.childById(request.childId)!;

    await rewardRepository.rejectRewardRequest(request.id);
    await rewardRepository.rejectRewardRequest(request.id);

    final updatedState = container
        .read(zeniAppStateControllerProvider)
        .asData!
        .value;
    final childAfter = updatedState.childById(request.childId)!;
    final refundedEntries = updatedState.starLedgerEntries
        .where((entry) => entry.relatedRewardRequestId == request.id)
        .where((entry) => entry.type == StarLedgerEntryType.refunded)
        .toList();

    expect(childAfter.starBalance, childBefore.starBalance + reward.cost);
    expect(refundedEntries, hasLength(1));
  });

  test(
    'canceling manual mission submission restores pending without side effects',
    () async {
      seedMockAppState();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final missionRepository = container.read(missionRepositoryProvider);
      await container.read(zeniAppStateControllerProvider.future);

      final initialState = container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value;
      final mission = initialState.missionById('mission-1')!;
      final childBefore = initialState.childById('child-1')!;
      final ledgerCountBefore = initialState.starLedgerEntries.length;
      final currentLog = initialState.missionLogs
          .where(
            (log) => log.missionId == mission.id && log.childId == 'child-1',
          )
          .firstOrNull;

      await missionRepository.submitMission(
        childId: 'child-1',
        mission: mission,
        currentLog: currentLog,
      );
      await missionRepository.cancelMissionSubmission(
        missionId: mission.id,
        childId: 'child-1',
      );

      final updatedState = container
          .read(zeniAppStateControllerProvider)
          .asData!
          .value;
      final childAfter = updatedState.childById('child-1')!;
      final pendingLog = updatedState.missionLogs
          .where((log) => log.id == currentLog!.id)
          .first;

      expect(pendingLog.status, MissionLogStatus.pending);
      expect(childAfter.streakCount, childBefore.streakCount);
      expect(childAfter.starBalance, childBefore.starBalance);
      expect(updatedState.starLedgerEntries.length, ledgerCountBefore);
    },
  );

  test('today logs repository excludes logs from previous days', () async {
    final initialState = ZeniAppState.seeded();
    final mission = initialState.missionById('mission-1')!;
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);

    final stateWithOldLog = initialState.copyWith(
      missionLogs: [
        MissionLog(
          id: 'old-log',
          missionId: mission.id,
          childId: 'child-1',
          scheduledDate: yesterday,
          status: MissionLogStatus.approved,
          starsAwarded: mission.stars,
        ),
        ...initialState.missionLogs,
      ],
    );

    SharedPreferences.setMockInitialValues({
      'zeni_app_state_v1': jsonEncode(stateWithOldLog.toJson()),
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final missionRepository = container.read(missionRepositoryProvider);
    await container.read(zeniAppStateControllerProvider.future);

    final todayLogs = await missionRepository.getTodayLogsForChild('child-1');

    expect(todayLogs, isNotEmpty);
    expect(todayLogs.any((log) => log.id == 'old-log'), isFalse);
    expect(
      todayLogs.every((log) {
        return log.scheduledDate.year == today.year &&
            log.scheduledDate.month == today.month &&
            log.scheduledDate.day == today.day;
      }),
      isTrue,
    );
  });
}
