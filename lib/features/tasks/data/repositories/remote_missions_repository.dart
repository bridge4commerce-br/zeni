import '../models/mission.dart';

class RemoteMissionSummary {
  const RemoteMissionSummary({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.localId,
    required this.title,
    required this.stars,
    required this.requiresApproval,
    required this.recurrenceType,
    required this.recurrenceDays,
    required this.isActive,
    this.archivedAt,
  });

  final String id;
  final String familyId;
  final String childId;
  final String? localId;
  final String title;
  final int stars;
  final bool requiresApproval;
  final String recurrenceType;
  final List<int> recurrenceDays;
  final bool isActive;
  final DateTime? archivedAt;
}

class ZeniEnsureRemoteMissionsResult {
  const ZeniEnsureRemoteMissionsResult({
    required this.isSuccess,
    this.missions = const <RemoteMissionSummary>[],
    this.message,
  });

  const ZeniEnsureRemoteMissionsResult.success(
    List<RemoteMissionSummary> missions,
  ) : this(isSuccess: true, missions: missions);

  const ZeniEnsureRemoteMissionsResult.failure(String message)
    : this(isSuccess: false, message: message);

  final bool isSuccess;
  final List<RemoteMissionSummary> missions;
  final String? message;
}

abstract class RemoteMissionsRepository {
  bool get isConfigured;

  Future<List<RemoteMissionSummary>> getRemoteMissions({
    required String familyId,
  });

  Future<ZeniEnsureRemoteMissionsResult> ensureRemoteMissions({
    required String familyId,
    required List<Mission> localMissions,
    required Map<String, String> remoteChildIdByLocalChildId,
  });
}
