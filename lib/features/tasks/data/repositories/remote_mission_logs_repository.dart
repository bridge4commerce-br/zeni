import '../models/mission_log.dart';

class RemoteMissionLogSummary {
  const RemoteMissionLogSummary({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.missionId,
    required this.localId,
    required this.status,
    required this.starsAwarded,
    required this.scheduledDate,
    this.submittedAt,
    this.completedAt,
    this.approvedAt,
    this.rejectedAt,
    this.photoUrl,
    this.note,
  });

  final String id;
  final String familyId;
  final String childId;
  final String missionId;
  final String? localId;
  final String status;
  final int starsAwarded;
  final DateTime scheduledDate;
  final DateTime? submittedAt;
  final DateTime? completedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? photoUrl;
  final String? note;
}

class ZeniEnsureRemoteMissionLogsResult {
  const ZeniEnsureRemoteMissionLogsResult({
    required this.isSuccess,
    this.missionLogs = const <RemoteMissionLogSummary>[],
    this.message,
  });

  const ZeniEnsureRemoteMissionLogsResult.success(
    List<RemoteMissionLogSummary> missionLogs,
  ) : this(isSuccess: true, missionLogs: missionLogs);

  const ZeniEnsureRemoteMissionLogsResult.failure(String message)
    : this(isSuccess: false, message: message);

  final bool isSuccess;
  final List<RemoteMissionLogSummary> missionLogs;
  final String? message;
}

abstract class RemoteMissionLogsRepository {
  bool get isConfigured;

  Future<List<RemoteMissionLogSummary>> getRemoteMissionLogs({
    required String familyId,
  });

  Future<ZeniEnsureRemoteMissionLogsResult> ensureRemoteMissionLogs({
    required String familyId,
    required List<MissionLog> localMissionLogs,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, String> remoteMissionIdByLocalMissionId,
  });
}
