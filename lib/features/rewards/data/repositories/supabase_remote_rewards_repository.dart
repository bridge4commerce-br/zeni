import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reward.dart';
import 'remote_rewards_repository.dart';

abstract class ZeniRewardsTableClient {
  Future<Map<String, dynamic>?> findByFamilyAndLocalId({
    required String familyId,
    required String localId,
  });

  Future<void> insertReward(Map<String, dynamic> payload);

  Future<void> updateReward({
    required String rewardId,
    required Map<String, dynamic> payload,
  });

  Future<List<Map<String, dynamic>>> fetchRewards({required String familyId});
}

class SupabaseRemoteRewardsRepository implements RemoteRewardsRepository {
  SupabaseRemoteRewardsRepository({
    required SupabaseClient? client,
    ZeniRewardsTableClient? tableClient,
    String? currentUserIdOverride,
  }) : _client = client,
       _tableClient =
           tableClient ??
           (client != null ? _SupabaseRewardsTableClient(client) : null),
       _currentUserIdOverride = currentUserIdOverride;

  final SupabaseClient? _client;
  final ZeniRewardsTableClient? _tableClient;
  final String? _currentUserIdOverride;

  @override
  bool get isConfigured => _tableClient != null;

  String? get _currentUserId =>
      _currentUserIdOverride ?? _client?.auth.currentUser?.id;

  @override
  Future<List<RemoteRewardSummary>> getRemoteRewards({
    required String familyId,
  }) async {
    final tableClient = _tableClient;
    if (tableClient == null || _currentUserId == null) {
      return const <RemoteRewardSummary>[];
    }

    try {
      final rows = await tableClient.fetchRewards(familyId: familyId);
      return rows.map(_parseReward).toList();
    } on PostgrestException catch (error) {
      _debugLog('getRemoteRewards error: ${error.message}');
      return const <RemoteRewardSummary>[];
    } catch (error) {
      _debugLog('getRemoteRewards unexpected error: $error');
      return const <RemoteRewardSummary>[];
    }
  }

  @override
  Future<ZeniEnsureRemoteRewardsResult> ensureRemoteRewards({
    required String familyId,
    required List<Reward> localRewards,
    required Map<String, String> remoteChildIdByLocalChildId,
  }) async {
    final tableClient = _tableClient;
    final currentUserId = _currentUserId;
    if (tableClient == null) {
      return const ZeniEnsureRemoteRewardsResult.failure(
        'Mimos remotos indisponíveis neste build.',
      );
    }

    if (currentUserId == null) {
      return const ZeniEnsureRemoteRewardsResult.failure(
        'Faça login para preparar os mimos na nuvem.',
      );
    }

    try {
      for (final reward in localRewards) {
        String? remoteChildId;
        if (reward.childId != null) {
          remoteChildId = remoteChildIdByLocalChildId[reward.childId!];
          if (remoteChildId == null || remoteChildId.isEmpty) {
            return const ZeniEnsureRemoteRewardsResult.failure(
              'Sincronize os dados principais primeiro para preparar os mimos.',
            );
          }
        }

        final existing = await tableClient.findByFamilyAndLocalId(
          familyId: familyId,
          localId: reward.id,
        );

        final payload = _buildPayload(
          reward: reward,
          familyId: familyId,
          remoteChildId: remoteChildId,
          existing: existing,
        );

        if (existing == null) {
          await tableClient.insertReward({
            ...payload,
            'created_by': currentUserId,
          });
        } else {
          await tableClient.updateReward(
            rewardId: existing['id'] as String,
            payload: payload,
          );
        }
      }

      final rewards = await getRemoteRewards(familyId: familyId);
      return ZeniEnsureRemoteRewardsResult.success(rewards);
    } on PostgrestException catch (error) {
      _debugLog('ensureRemoteRewards error: ${error.message}');
      return const ZeniEnsureRemoteRewardsResult.failure(
        'Não foi possível preparar os mimos na nuvem agora.',
      );
    } catch (error) {
      _debugLog('ensureRemoteRewards unexpected error: $error');
      return const ZeniEnsureRemoteRewardsResult.failure(
        'Não foi possível preparar os mimos na nuvem agora.',
      );
    }
  }

  Map<String, dynamic> _buildPayload({
    required Reward reward,
    required String familyId,
    required String? remoteChildId,
    required Map<String, dynamic>? existing,
  }) {
    final archivedAt = reward.isActive
        ? null
        : (existing?['archived_at'] as String? ??
              DateTime.now().toIso8601String());

    return {
      'family_id': familyId,
      'child_id': remoteChildId,
      'local_id': reward.id,
      'title': reward.title,
      'description': reward.description,
      'cost': reward.cost,
      'image_key': reward.emoji,
      'is_active': reward.isActive,
      'archived_at': archivedAt,
    };
  }

  RemoteRewardSummary _parseReward(Map<String, dynamic> data) {
    return RemoteRewardSummary(
      id: data['id'] as String? ?? '',
      familyId: data['family_id'] as String? ?? '',
      childId: data['child_id'] as String?,
      localId: data['local_id'] as String?,
      title: data['title'] as String? ?? '',
      cost: data['cost'] as int? ?? 1,
      imageKey: data['image_key'] as String?,
      isActive: data['is_active'] as bool? ?? true,
      archivedAt: data['archived_at'] == null
          ? null
          : DateTime.parse(data['archived_at'] as String),
    );
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[ZeniRemoteRewards] $message');
  }
}

class _SupabaseRewardsTableClient implements ZeniRewardsTableClient {
  const _SupabaseRewardsTableClient(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchRewards({
    required String familyId,
  }) async {
    final response = await _client
        .from('rewards')
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
        .from('rewards')
        .select()
        .eq('family_id', familyId)
        .eq('local_id', localId)
        .maybeSingle();
    return response;
  }

  @override
  Future<void> insertReward(Map<String, dynamic> payload) async {
    await _client.from('rewards').insert(payload);
  }

  @override
  Future<void> updateReward({
    required String rewardId,
    required Map<String, dynamic> payload,
  }) async {
    await _client.from('rewards').update(payload).eq('id', rewardId);
  }
}
