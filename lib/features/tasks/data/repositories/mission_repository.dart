import '../../../../core/domain/zeni_enums.dart';
import '../models/mission.dart';
import '../models/mission_log.dart';

abstract class MissionRepository {
  Future<List<Mission>> getMissionsForFamily(String familyId);

  Future<List<Mission>> getMissionsForChild(String childId);

  Future<List<MissionLog>> getTodayLogsForChild(String childId);

  Future<List<MissionLog>> getAwaitingApprovalLogs();

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
  });

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
  });

  Future<Mission?> archiveMission(String missionId);

  Future<Mission?> restoreMission(String missionId);

  Future<void> submitMission({
    required String childId,
    required Mission mission,
    required MissionLog? currentLog,
    String? note,
  });

  Future<void> cancelMissionSubmission({
    required String missionId,
    required String childId,
  });

  Future<void> approveMissionLog(String logId);

  Future<void> rejectMissionLog(String logId);
}
