import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../models/mission.dart';
import '../models/mission_log.dart';
import 'mission_repository.dart';

class MockMissionRepository implements MissionRepository {
  MockMissionRepository(this._ref);

  final Ref _ref;

  @override
  Future<List<Mission>> getMissionsForFamily(String familyId) async {
    return (await _ref.read(zeniAppStateControllerProvider.future)).missions
        .where((mission) => mission.familyId == familyId && mission.isActive)
        .toList();
  }

  @override
  Future<List<Mission>> getMissionsForChild(String childId) async {
    return (await _ref.read(zeniAppStateControllerProvider.future)).missions
        .where((mission) => mission.childId == childId && mission.isActive)
        .toList();
  }

  @override
  Future<List<MissionLog>> getTodayLogsForChild(String childId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return (await _ref.read(zeniAppStateControllerProvider.future)).missionLogs
        .where(
          (log) =>
              log.childId == childId &&
              DateTime(
                    log.scheduledDate.year,
                    log.scheduledDate.month,
                    log.scheduledDate.day,
                  ) ==
                  today,
        )
        .toList();
  }

  @override
  Future<List<MissionLog>> getAwaitingApprovalLogs() async {
    return (await _ref.read(zeniAppStateControllerProvider.future)).missionLogs
        .where((log) => log.status == MissionLogStatus.awaitingApproval)
        .toList();
  }

  @override
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
  }) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .createMission(
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
        );
  }

  @override
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
  }) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .updateMission(
          missionId: missionId,
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
        );
  }

  @override
  Future<Mission?> archiveMission(String missionId) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .archiveMission(missionId);
  }

  @override
  Future<Mission?> restoreMission(String missionId) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .restoreMission(missionId);
  }

  @override
  Future<void> submitMission({
    required String childId,
    required Mission mission,
    required MissionLog? currentLog,
    String? note,
  }) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .submitMission(
          childId: childId,
          mission: mission,
          currentLog: currentLog,
          note: note,
        );
  }

  @override
  Future<void> cancelMissionSubmission({
    required String missionId,
    required String childId,
  }) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .cancelMissionSubmission(missionId: missionId, childId: childId);
  }

  @override
  Future<void> approveMissionLog(String logId) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .approveMissionLog(logId);
  }

  @override
  Future<void> rejectMissionLog(String logId) {
    return _ref
        .read(zeniAppStateControllerProvider.notifier)
        .rejectMissionLog(logId);
  }
}
