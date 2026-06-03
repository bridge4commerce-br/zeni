import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mission_log.dart';
import 'remote_mission_logs_repository.dart';

abstract class ZeniMissionLogsTableClient {
  Future<Map<String, dynamic>?> findByFamilyAndLocalId({
    required String familyId,
    required String localId,
  });

  Future<void> insertMissionLog(Map<String, dynamic> payload);

  Future<void> updateMissionLog({
    required String missionLogId,
    required Map<String, dynamic> payload,
  });

  Future<List<Map<String, dynamic>>> fetchMissionLogs({
    required String familyId,
  });
}

class SupabaseRemoteMissionLogsRepository
    implements RemoteMissionLogsRepository {
  SupabaseRemoteMissionLogsRepository({
    required SupabaseClient? client,
    ZeniMissionLogsTableClient? tableClient,
    String? currentUserIdOverride,
  }) : _client = client,
       _tableClient =
           tableClient ??
           (client != null ? _SupabaseMissionLogsTableClient(client) : null),
       _currentUserIdOverride = currentUserIdOverride;

  final SupabaseClient? _client;
  final ZeniMissionLogsTableClient? _tableClient;
  final String? _currentUserIdOverride;

  @override
  bool get isConfigured => _tableClient != null;

  String? get _currentUserId =>
      _currentUserIdOverride ?? _client?.auth.currentUser?.id;

  @override
  Future<List<RemoteMissionLogSummary>> getRemoteMissionLogs({
    required String familyId,
  }) async {
    final tableClient = _tableClient;
    if (tableClient == null || _currentUserId == null) {
      return const <RemoteMissionLogSummary>[];
    }

    try {
      final rows = await tableClient.fetchMissionLogs(familyId: familyId);
      return rows.map(_parseMissionLog).toList();
    } on PostgrestException catch (error) {
      _debugLog('getRemoteMissionLogs error: ${error.message}');
      return const <RemoteMissionLogSummary>[];
    } catch (error) {
      _debugLog('getRemoteMissionLogs unexpected error: $error');
      return const <RemoteMissionLogSummary>[];
    }
  }

  @override
  Future<ZeniEnsureRemoteMissionLogsResult> ensureRemoteMissionLogs({
    required String familyId,
    required List<MissionLog> localMissionLogs,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, String> remoteMissionIdByLocalMissionId,
  }) async {
    final tableClient = _tableClient;
    final currentUserId = _currentUserId;
    if (tableClient == null) {
      return const ZeniEnsureRemoteMissionLogsResult.failure(
        'Logs remotos de missão indisponíveis neste build.',
      );
    }

    if (currentUserId == null) {
      return const ZeniEnsureRemoteMissionLogsResult.failure(
        'Faça login para preparar as conclusões na nuvem.',
      );
    }

    try {
      for (final log in localMissionLogs) {
        final remoteChildId = remoteChildIdByLocalChildId[log.childId];
        final remoteMissionId = remoteMissionIdByLocalMissionId[log.missionId];

        if (remoteChildId == null ||
            remoteChildId.isEmpty ||
            remoteMissionId == null ||
            remoteMissionId.isEmpty) {
          return const ZeniEnsureRemoteMissionLogsResult.failure(
            'Sincronize os dados principais primeiro para preparar as conclusões.',
          );
        }

        final existing = await tableClient.findByFamilyAndLocalId(
          familyId: familyId,
          localId: log.id,
        );

        final payload = _buildPayload(
          log: log,
          familyId: familyId,
          remoteChildId: remoteChildId,
          remoteMissionId: remoteMissionId,
        );

        if (existing == null) {
          await tableClient.insertMissionLog({
            ...payload,
            'created_by': currentUserId,
          });
        } else {
          await tableClient.updateMissionLog(
            missionLogId: existing['id'] as String,
            payload: payload,
          );
        }
      }

      final logs = await getRemoteMissionLogs(familyId: familyId);
      return ZeniEnsureRemoteMissionLogsResult.success(logs);
    } on PostgrestException catch (error) {
      _debugLog('ensureRemoteMissionLogs error: ${error.message}');
      return ZeniEnsureRemoteMissionLogsResult.failure(
        _friendlyMessage(error.message),
      );
    } catch (error) {
      _debugLog('ensureRemoteMissionLogs unexpected error: $error');
      return const ZeniEnsureRemoteMissionLogsResult.failure(
        'Não foi possível preparar as conclusões na nuvem agora.',
      );
    }
  }

  Map<String, dynamic> _buildPayload({
    required MissionLog log,
    required String familyId,
    required String remoteChildId,
    required String remoteMissionId,
  }) {
    return {
      'family_id': familyId,
      'child_id': remoteChildId,
      'mission_id': remoteMissionId,
      'local_id': log.id,
      'status': log.status.name,
      'scheduled_date': _dateOnly(log.scheduledDate),
      'stars_awarded': log.starsAwarded,
      'submitted_at': _submittedAt(log)?.toIso8601String(),
      'completed_at': log.completedAt?.toIso8601String(),
      'approved_at': log.approvedAt?.toIso8601String(),
      'rejected_at': log.rejectedAt?.toIso8601String(),
      'note': log.note,
    };
  }

  DateTime? _submittedAt(MissionLog log) {
    return log.completedAt ?? log.approvedAt ?? log.rejectedAt;
  }

  String _dateOnly(DateTime value) => value.toIso8601String().split('T').first;

  String _friendlyMessage(String errorMessage) {
    return 'Não foi possível preparar as conclusões na nuvem agora.';
  }

  RemoteMissionLogSummary _parseMissionLog(Map<String, dynamic> data) {
    return RemoteMissionLogSummary(
      id: data['id'] as String? ?? '',
      familyId: data['family_id'] as String? ?? '',
      childId: data['child_id'] as String? ?? '',
      missionId: data['mission_id'] as String? ?? '',
      localId: data['local_id'] as String?,
      status: data['status'] as String? ?? 'pending',
      starsAwarded: data['stars_awarded'] as int? ?? 0,
      scheduledDate: DateTime.parse(
        data['scheduled_date'] as String? ?? DateTime.now().toIso8601String(),
      ),
      submittedAt: data['submitted_at'] == null
          ? null
          : DateTime.parse(data['submitted_at'] as String),
      completedAt: data['completed_at'] == null
          ? null
          : DateTime.parse(data['completed_at'] as String),
      approvedAt: data['approved_at'] == null
          ? null
          : DateTime.parse(data['approved_at'] as String),
      rejectedAt: data['rejected_at'] == null
          ? null
          : DateTime.parse(data['rejected_at'] as String),
      photoUrl: data['photo_url'] as String?,
      note: data['note'] as String?,
    );
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[ZeniRemoteMissionLogs] $message');
  }
}

class _SupabaseMissionLogsTableClient implements ZeniMissionLogsTableClient {
  const _SupabaseMissionLogsTableClient(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchMissionLogs({
    required String familyId,
  }) async {
    final response = await _client
        .from('mission_logs')
        .select()
        .eq('family_id', familyId)
        .order('created_at');
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>?> findByFamilyAndLocalId({
    required String familyId,
    required String localId,
  }) async {
    final response = await _client
        .from('mission_logs')
        .select()
        .eq('family_id', familyId)
        .eq('local_id', localId)
        .maybeSingle();
    return response;
  }

  @override
  Future<void> insertMissionLog(Map<String, dynamic> payload) async {
    await _client.from('mission_logs').insert(payload);
  }

  @override
  Future<void> updateMissionLog({
    required String missionLogId,
    required Map<String, dynamic> payload,
  }) async {
    await _client.from('mission_logs').update(payload).eq('id', missionLogId);
  }
}
