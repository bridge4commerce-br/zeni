import '../models/star_ledger_entry.dart';

class RemoteStarLedgerEntrySummary {
  const RemoteStarLedgerEntrySummary({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.sourceType,
    required this.sourceLocalId,
    required this.idempotencyKey,
    required this.direction,
    required this.amount,
    required this.occurredAt,
    this.createdAt,
    this.sourceId,
    this.reason,
  });

  final String id;
  final String familyId;
  final String childId;
  final String sourceType;
  final String? sourceId;
  final String? sourceLocalId;
  final String idempotencyKey;
  final String direction;
  final int amount;
  final String? reason;
  final DateTime occurredAt;
  final DateTime? createdAt;
}

class ZeniEnsureRemoteStarLedgerResult {
  const ZeniEnsureRemoteStarLedgerResult({
    required this.isSuccess,
    this.entries = const <RemoteStarLedgerEntrySummary>[],
    this.message,
  });

  const ZeniEnsureRemoteStarLedgerResult.success(
    List<RemoteStarLedgerEntrySummary> entries,
  ) : this(isSuccess: true, entries: entries);

  const ZeniEnsureRemoteStarLedgerResult.failure(String message)
    : this(isSuccess: false, message: message);

  final bool isSuccess;
  final List<RemoteStarLedgerEntrySummary> entries;
  final String? message;
}

abstract class RemoteStarLedgerRepository {
  bool get isConfigured;

  Future<List<RemoteStarLedgerEntrySummary>> getRemoteStarLedgerEntries({
    required String familyId,
  });

  Future<ZeniEnsureRemoteStarLedgerResult> ensureRemoteStarLedger({
    required String familyId,
    required List<StarLedgerEntry> localEntries,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, String> remoteMissionLogIdByLocalMissionLogId,
    required Map<String, String> remoteRewardRequestIdByLocalRewardRequestId,
  });
}
