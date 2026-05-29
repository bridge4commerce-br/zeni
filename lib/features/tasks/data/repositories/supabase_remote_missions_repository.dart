import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../models/mission.dart';
import 'remote_missions_repository.dart';

abstract class ZeniMissionsTableClient {
  Future<Map<String, dynamic>?> findByFamilyAndLocalId({
    required String familyId,
    required String localId,
  });

  Future<void> insertMission(Map<String, dynamic> payload);

  Future<void> updateMission({
    required String missionId,
    required Map<String, dynamic> payload,
  });

  Future<List<Map<String, dynamic>>> fetchMissions({required String familyId});
}

class SupabaseRemoteMissionsRepository implements RemoteMissionsRepository {
  SupabaseRemoteMissionsRepository({
    required SupabaseClient? client,
    ZeniMissionsTableClient? tableClient,
    String? currentUserIdOverride,
  }) : _client = client,
       _tableClient = tableClient ?? (client != null ? _SupabaseMissionsTableClient(client) : null),
       _currentUserIdOverride = currentUserIdOverride;

  final SupabaseClient? _client;
  final ZeniMissionsTableClient? _tableClient;
  final String? _currentUserIdOverride;

  @override
  bool get isConfigured => _tableClient != null;

  String? get _currentUserId =>
      _currentUserIdOverride ?? _client?.auth.currentUser?.id;

  @override
  Future<List<RemoteMissionSummary>> getRemoteMissions({
    required String familyId,
  }) async {
    final tableClient = _tableClient;
    if (tableClient == null || _currentUserId == null) {
      return const <RemoteMissionSummary>[];
    }

    try {
      final rows = await tableClient.fetchMissions(familyId: familyId);
      return rows.map(_parseMission).toList();
    } on PostgrestException catch (error) {
      _debugLog('getRemoteMissions error: ${error.message}');
      return const <RemoteMissionSummary>[];
    } catch (error) {
      _debugLog('getRemoteMissions unexpected error: $error');
      return const <RemoteMissionSummary>[];
    }
  }

  @override
  Future<ZeniEnsureRemoteMissionsResult> ensureRemoteMissions({
    required String familyId,
    required List<Mission> localMissions,
    required Map<String, String> remoteChildIdByLocalChildId,
  }) async {
    final tableClient = _tableClient;
    final currentUserId = _currentUserId;
    if (tableClient == null) {
      return const ZeniEnsureRemoteMissionsResult.failure(
        'Missões remotas indisponíveis neste build.',
      );
    }

    if (currentUserId == null) {
      return const ZeniEnsureRemoteMissionsResult.failure(
        'Faça login para preparar as missões na nuvem.',
      );
    }

    try {
      for (final mission in localMissions) {
        final remoteChildId = remoteChildIdByLocalChildId[mission.childId];
        if (remoteChildId == null || remoteChildId.isEmpty) {
          return const ZeniEnsureRemoteMissionsResult.failure(
            'Prepare as crianças na nuvem antes de sincronizar as missões.',
          );
        }

        final existing = await tableClient.findByFamilyAndLocalId(
          familyId: familyId,
          localId: mission.id,
        );

        final payload = _buildPayload(
          mission: mission,
          familyId: familyId,
          remoteChildId: remoteChildId,
          existing: existing,
        );

        if (existing == null) {
          await tableClient.insertMission({
            ...payload,
            'created_by': currentUserId,
          });
        } else {
          await tableClient.updateMission(
            missionId: existing['id'] as String,
            payload: payload,
          );
        }
      }

      final missions = await getRemoteMissions(familyId: familyId);
      return ZeniEnsureRemoteMissionsResult.success(missions);
    } on PostgrestException catch (error) {
      _debugLog('ensureRemoteMissions error: ${error.message}');
      return const ZeniEnsureRemoteMissionsResult.failure(
        'Não foi possível preparar as missões na nuvem agora.',
      );
    } catch (error) {
      _debugLog('ensureRemoteMissions unexpected error: $error');
      return const ZeniEnsureRemoteMissionsResult.failure(
        'Não foi possível preparar as missões na nuvem agora.',
      );
    }
  }

  Map<String, dynamic> _buildPayload({
    required Mission mission,
    required String familyId,
    required String remoteChildId,
    required Map<String, dynamic>? existing,
  }) {
    final archivedAt = mission.status == MissionStatus.archived
        ? (existing?['archived_at'] as String? ?? DateTime.now().toIso8601String())
        : null;

    return {
      'family_id': familyId,
      'child_id': remoteChildId,
      'local_id': mission.id,
      'title': mission.title,
      'description': mission.description,
      'stars': mission.stars,
      'requires_approval':
          mission.approvalMode == MissionApprovalMode.parentApproval,
      'recurrence_type': mission.recurrence.storageValue,
      'recurrence_days': mission.recurrence == MissionRecurrence.customDaysOfWeek
          ? mission.effectiveCustomDaysOfWeek
          : null,
      'is_active': mission.isActive,
      'archived_at': archivedAt,
    };
  }

  RemoteMissionSummary _parseMission(Map<String, dynamic> data) {
    return RemoteMissionSummary(
      id: data['id'] as String? ?? '',
      familyId: data['family_id'] as String? ?? '',
      childId: data['child_id'] as String? ?? '',
      localId: data['local_id'] as String?,
      title: data['title'] as String? ?? '',
      stars: data['stars'] as int? ?? 1,
      requiresApproval: data['requires_approval'] as bool? ?? false,
      recurrenceType: data['recurrence_type'] as String? ?? 'daily',
      recurrenceDays: (data['recurrence_days'] as List<dynamic>? ?? const [])
          .whereType<num>()
          .map((day) => day.toInt())
          .toList(),
      isActive: data['is_active'] as bool? ?? true,
      archivedAt: data['archived_at'] == null
          ? null
          : DateTime.parse(data['archived_at'] as String),
    );
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[ZeniRemoteMissions] $message');
  }
}

class _SupabaseMissionsTableClient implements ZeniMissionsTableClient {
  const _SupabaseMissionsTableClient(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchMissions({
    required String familyId,
  }) async {
    final response = await _client
        .from('missions')
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
        .from('missions')
        .select()
        .eq('family_id', familyId)
        .eq('local_id', localId)
        .maybeSingle();
    return response;
  }

  @override
  Future<void> insertMission(Map<String, dynamic> payload) async {
    await _client.from('missions').insert(payload);
  }

  @override
  Future<void> updateMission({
    required String missionId,
    required Map<String, dynamic> payload,
  }) async {
    await _client.from('missions').update(payload).eq('id', missionId);
  }
}
