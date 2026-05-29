import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../models/star_ledger_entry.dart';
import 'remote_star_ledger_repository.dart';

abstract class ZeniStarLedgerTableClient {
  Future<Map<String, dynamic>?> findByFamilyAndIdempotencyKey({
    required String familyId,
    required String idempotencyKey,
  });

  Future<void> insertEntry(Map<String, dynamic> payload);

  Future<void> updateEntry({
    required String entryId,
    required Map<String, dynamic> payload,
  });

  Future<List<Map<String, dynamic>>> fetchEntries({required String familyId});
}

class SupabaseRemoteStarLedgerRepository implements RemoteStarLedgerRepository {
  SupabaseRemoteStarLedgerRepository({
    required SupabaseClient? client,
    ZeniStarLedgerTableClient? tableClient,
    String? currentUserIdOverride,
  }) : _client = client,
       _tableClient =
           tableClient ??
           (client != null ? _SupabaseStarLedgerTableClient(client) : null),
       _currentUserIdOverride = currentUserIdOverride;

  final SupabaseClient? _client;
  final ZeniStarLedgerTableClient? _tableClient;
  final String? _currentUserIdOverride;

  @override
  bool get isConfigured => _tableClient != null;

  String? get _currentUserId =>
      _currentUserIdOverride ?? _client?.auth.currentUser?.id;

  @override
  Future<List<RemoteStarLedgerEntrySummary>> getRemoteStarLedgerEntries({
    required String familyId,
  }) async {
    final tableClient = _tableClient;
    if (tableClient == null || _currentUserId == null) {
      return const <RemoteStarLedgerEntrySummary>[];
    }

    try {
      final rows = await tableClient.fetchEntries(familyId: familyId);
      return rows.map(_parseEntry).toList();
    } on PostgrestException catch (error) {
      _debugLog('getRemoteStarLedgerEntries error: ${error.message}');
      return const <RemoteStarLedgerEntrySummary>[];
    } catch (error) {
      _debugLog('getRemoteStarLedgerEntries unexpected error: $error');
      return const <RemoteStarLedgerEntrySummary>[];
    }
  }

  @override
  Future<ZeniEnsureRemoteStarLedgerResult> ensureRemoteStarLedger({
    required String familyId,
    required List<StarLedgerEntry> localEntries,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, String> remoteMissionLogIdByLocalMissionLogId,
    required Map<String, String> remoteRewardRequestIdByLocalRewardRequestId,
  }) async {
    final tableClient = _tableClient;
    final currentUserId = _currentUserId;
    if (tableClient == null) {
      return const ZeniEnsureRemoteStarLedgerResult.failure(
        'Ledger remoto indisponível neste build.',
      );
    }

    if (currentUserId == null) {
      return const ZeniEnsureRemoteStarLedgerResult.failure(
        'Faça login para preparar o histórico de estrelas na nuvem.',
      );
    }

    try {
      for (final entry in localEntries) {
        final payloadResult = _buildPayload(
          entry: entry,
          familyId: familyId,
          remoteChildIdByLocalChildId: remoteChildIdByLocalChildId,
          remoteMissionLogIdByLocalMissionLogId:
              remoteMissionLogIdByLocalMissionLogId,
          remoteRewardRequestIdByLocalRewardRequestId:
              remoteRewardRequestIdByLocalRewardRequestId,
        );
        if (!payloadResult.isSuccess) {
          return ZeniEnsureRemoteStarLedgerResult.failure(
            payloadResult.message!,
          );
        }

        final payload = payloadResult.payload!;
        final existing = await tableClient.findByFamilyAndIdempotencyKey(
          familyId: familyId,
          idempotencyKey: payload['idempotency_key'] as String,
        );

        if (existing == null) {
          await tableClient.insertEntry({
            ...payload,
            'created_by': currentUserId,
          });
        } else {
          await tableClient.updateEntry(
            entryId: existing['id'] as String,
            payload: payload,
          );
        }
      }

      final entries = await getRemoteStarLedgerEntries(familyId: familyId);
      return ZeniEnsureRemoteStarLedgerResult.success(entries);
    } on PostgrestException catch (error) {
      _debugLog('ensureRemoteStarLedger error: ${error.message}');
      return const ZeniEnsureRemoteStarLedgerResult.failure(
        'Não foi possível preparar o histórico de estrelas na nuvem agora.',
      );
    } catch (error) {
      _debugLog('ensureRemoteStarLedger unexpected error: $error');
      return const ZeniEnsureRemoteStarLedgerResult.failure(
        'Não foi possível preparar o histórico de estrelas na nuvem agora.',
      );
    }
  }

  _PayloadBuildResult _buildPayload({
    required StarLedgerEntry entry,
    required String familyId,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, String> remoteMissionLogIdByLocalMissionLogId,
    required Map<String, String> remoteRewardRequestIdByLocalRewardRequestId,
  }) {
    final remoteChildId = remoteChildIdByLocalChildId[entry.childId];
    if (remoteChildId == null || remoteChildId.isEmpty) {
      return const _PayloadBuildResult.failure(
        'Sincronize os dados principais primeiro para preparar o histórico de estrelas.',
      );
    }

    final amount = entry.amount.abs();
    if (amount <= 0) {
      return const _PayloadBuildResult.failure(
        'Alguns eventos locais ainda não podem ser preparados na nuvem.',
      );
    }

    if (entry.relatedMissionLogId != null &&
        entry.relatedMissionLogId!.isNotEmpty) {
      final sourceLocalId = entry.relatedMissionLogId!;
      final remoteSourceId =
          remoteMissionLogIdByLocalMissionLogId[sourceLocalId];
      if (remoteSourceId == null || remoteSourceId.isEmpty) {
        return const _PayloadBuildResult.failure(
          'Sincronize os dados principais primeiro para preparar o histórico de estrelas.',
        );
      }

      return _PayloadBuildResult.success({
        'family_id': familyId,
        'child_id': remoteChildId,
        'source_type': 'mission_log',
        'source_id': remoteSourceId,
        'source_local_id': sourceLocalId,
        'idempotency_key': 'mission_log:$sourceLocalId:earned',
        'direction': 'credit',
        'amount': amount,
        'reason': entry.description ?? entry.title,
        'occurred_at': entry.createdAt.toIso8601String(),
      });
    }

    if (entry.relatedRewardRequestId != null &&
        entry.relatedRewardRequestId!.isNotEmpty) {
      final sourceLocalId = entry.relatedRewardRequestId!;
      final remoteSourceId =
          remoteRewardRequestIdByLocalRewardRequestId[sourceLocalId];
      if (remoteSourceId == null || remoteSourceId.isEmpty) {
        return const _PayloadBuildResult.failure(
          'Sincronize os dados principais primeiro para preparar o histórico de estrelas.',
        );
      }

      final isRefund = entry.type == StarLedgerEntryType.refunded;
      final isSpent = entry.type == StarLedgerEntryType.spent;
      if (!isRefund && !isSpent) {
        return const _PayloadBuildResult.failure(
          'Alguns eventos locais ainda não podem ser preparados na nuvem.',
        );
      }

      return _PayloadBuildResult.success({
        'family_id': familyId,
        'child_id': remoteChildId,
        'source_type': 'reward_request',
        'source_id': remoteSourceId,
        'source_local_id': sourceLocalId,
        'idempotency_key':
            'reward_request:$sourceLocalId:${isRefund ? 'refunded' : 'spent'}',
        'direction': isRefund ? 'credit' : 'debit',
        'amount': amount,
        'reason': entry.description ?? entry.title,
        'occurred_at': entry.createdAt.toIso8601String(),
      });
    }

    return _PayloadBuildResult.success({
      'family_id': familyId,
      'child_id': remoteChildId,
      'source_type': 'manual_adjustment',
      'source_id': null,
      'source_local_id': entry.id,
      'idempotency_key': 'manual_adjustment:${entry.id}',
      'direction': entry.amount >= 0 ? 'credit' : 'debit',
      'amount': amount,
      'reason': entry.description ?? entry.title,
      'occurred_at': entry.createdAt.toIso8601String(),
    });
  }

  RemoteStarLedgerEntrySummary _parseEntry(Map<String, dynamic> data) {
    return RemoteStarLedgerEntrySummary(
      id: data['id'] as String? ?? '',
      familyId: data['family_id'] as String? ?? '',
      childId: data['child_id'] as String? ?? '',
      sourceType: data['source_type'] as String? ?? 'manual_adjustment',
      sourceId: data['source_id'] as String?,
      sourceLocalId: data['source_local_id'] as String?,
      idempotencyKey: data['idempotency_key'] as String? ?? '',
      direction: data['direction'] as String? ?? 'credit',
      amount: data['amount'] as int? ?? 0,
      reason: data['reason'] as String?,
      occurredAt: DateTime.parse(
        data['occurred_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[ZeniRemoteStarLedger] $message');
  }
}

class _SupabaseStarLedgerTableClient implements ZeniStarLedgerTableClient {
  const _SupabaseStarLedgerTableClient(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchEntries({
    required String familyId,
  }) async {
    final response = await _client
        .from('star_ledger_entries')
        .select()
        .eq('family_id', familyId)
        .order('occurred_at');
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>?> findByFamilyAndIdempotencyKey({
    required String familyId,
    required String idempotencyKey,
  }) async {
    final response = await _client
        .from('star_ledger_entries')
        .select()
        .eq('family_id', familyId)
        .eq('idempotency_key', idempotencyKey)
        .maybeSingle();
    return response;
  }

  @override
  Future<void> insertEntry(Map<String, dynamic> payload) async {
    await _client.from('star_ledger_entries').insert(payload);
  }

  @override
  Future<void> updateEntry({
    required String entryId,
    required Map<String, dynamic> payload,
  }) async {
    await _client.from('star_ledger_entries').update(payload).eq('id', entryId);
  }
}

class _PayloadBuildResult {
  const _PayloadBuildResult({
    required this.isSuccess,
    this.payload,
    this.message,
  });

  const _PayloadBuildResult.success(Map<String, dynamic> payload)
    : this(isSuccess: true, payload: payload);

  const _PayloadBuildResult.failure(String message)
    : this(isSuccess: false, message: message);

  final bool isSuccess;
  final Map<String, dynamic>? payload;
  final String? message;
}
