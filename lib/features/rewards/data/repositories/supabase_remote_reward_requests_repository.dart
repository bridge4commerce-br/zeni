import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../models/reward_request.dart';
import 'remote_reward_requests_repository.dart';

abstract class ZeniRewardRequestsTableClient {
  Future<Map<String, dynamic>?> findByFamilyAndLocalId({
    required String familyId,
    required String localId,
  });

  Future<void> insertRewardRequest(Map<String, dynamic> payload);

  Future<void> updateRewardRequest({
    required String rewardRequestId,
    required Map<String, dynamic> payload,
  });

  Future<List<Map<String, dynamic>>> fetchRewardRequests({
    required String familyId,
  });
}

class SupabaseRemoteRewardRequestsRepository
    implements RemoteRewardRequestsRepository {
  SupabaseRemoteRewardRequestsRepository({
    required SupabaseClient? client,
    ZeniRewardRequestsTableClient? tableClient,
    String? currentUserIdOverride,
  }) : _client = client,
       _tableClient =
           tableClient ??
           (client != null ? _SupabaseRewardRequestsTableClient(client) : null),
       _currentUserIdOverride = currentUserIdOverride;

  final SupabaseClient? _client;
  final ZeniRewardRequestsTableClient? _tableClient;
  final String? _currentUserIdOverride;

  @override
  bool get isConfigured => _tableClient != null;

  String? get _currentUserId =>
      _currentUserIdOverride ?? _client?.auth.currentUser?.id;

  @override
  Future<List<RemoteRewardRequestSummary>> getRemoteRewardRequests({
    required String familyId,
  }) async {
    final tableClient = _tableClient;
    if (tableClient == null || _currentUserId == null) {
      return const <RemoteRewardRequestSummary>[];
    }

    try {
      final rows = await tableClient.fetchRewardRequests(familyId: familyId);
      return rows.map(_parseRewardRequest).toList();
    } on PostgrestException catch (error) {
      _debugLog('getRemoteRewardRequests error: ${error.message}');
      return const <RemoteRewardRequestSummary>[];
    } catch (error) {
      _debugLog('getRemoteRewardRequests unexpected error: $error');
      return const <RemoteRewardRequestSummary>[];
    }
  }

  @override
  Future<ZeniEnsureRemoteRewardRequestsResult> ensureRemoteRewardRequests({
    required String familyId,
    required List<RewardRequest> localRewardRequests,
    required Map<String, String> remoteChildIdByLocalChildId,
    required Map<String, ({String remoteRewardId, int cost})>
    remoteRewardByLocalRewardId,
  }) async {
    final tableClient = _tableClient;
    final currentUserId = _currentUserId;
    if (tableClient == null) {
      return const ZeniEnsureRemoteRewardRequestsResult.failure(
        'Pedidos remotos de mimos indisponíveis neste build.',
      );
    }

    if (currentUserId == null) {
      return const ZeniEnsureRemoteRewardRequestsResult.failure(
        'Faça login para preparar os pedidos na nuvem.',
      );
    }

    try {
      for (final request in localRewardRequests) {
        final remoteChildId = remoteChildIdByLocalChildId[request.childId];
        final remoteReward = remoteRewardByLocalRewardId[request.rewardId];
        if (remoteChildId == null ||
            remoteChildId.isEmpty ||
            remoteReward == null ||
            remoteReward.remoteRewardId.isEmpty) {
          return const ZeniEnsureRemoteRewardRequestsResult.failure(
            'Sincronize os dados principais primeiro para preparar os pedidos.',
          );
        }

        final existing = await tableClient.findByFamilyAndLocalId(
          familyId: familyId,
          localId: request.id,
        );

        final payload = _buildPayload(
          request: request,
          familyId: familyId,
          remoteChildId: remoteChildId,
          remoteRewardId: remoteReward.remoteRewardId,
          starsSpent: remoteReward.cost,
        );

        if (existing == null) {
          await tableClient.insertRewardRequest({
            ...payload,
            'created_by': currentUserId,
          });
        } else {
          await tableClient.updateRewardRequest(
            rewardRequestId: existing['id'] as String,
            payload: payload,
          );
        }
      }

      final requests = await getRemoteRewardRequests(familyId: familyId);
      return ZeniEnsureRemoteRewardRequestsResult.success(requests);
    } on PostgrestException catch (error) {
      _debugLog('ensureRemoteRewardRequests error: ${error.message}');
      return const ZeniEnsureRemoteRewardRequestsResult.failure(
        'Não foi possível preparar os pedidos na nuvem agora.',
      );
    } catch (error) {
      _debugLog('ensureRemoteRewardRequests unexpected error: $error');
      return const ZeniEnsureRemoteRewardRequestsResult.failure(
        'Não foi possível preparar os pedidos na nuvem agora.',
      );
    }
  }

  Map<String, dynamic> _buildPayload({
    required RewardRequest request,
    required String familyId,
    required String remoteChildId,
    required String remoteRewardId,
    required int starsSpent,
  }) {
    return {
      'family_id': familyId,
      'child_id': remoteChildId,
      'reward_id': remoteRewardId,
      'local_id': request.id,
      'status': request.status.name,
      'stars_spent': starsSpent,
      'requested_at': request.requestedAt.toIso8601String(),
      'approved_at':
          request.status == RewardRequestStatus.approved ||
              request.status == RewardRequestStatus.delivered
          ? request.resolvedAt?.toIso8601String()
          : null,
      'rejected_at': request.status == RewardRequestStatus.rejected
          ? request.resolvedAt?.toIso8601String()
          : null,
      'cancelled_at': request.status == RewardRequestStatus.cancelled
          ? request.resolvedAt?.toIso8601String()
          : null,
      'note': request.note,
      'rejection_reason': null,
    };
  }

  RemoteRewardRequestSummary _parseRewardRequest(Map<String, dynamic> data) {
    return RemoteRewardRequestSummary(
      id: data['id'] as String? ?? '',
      familyId: data['family_id'] as String? ?? '',
      childId: data['child_id'] as String? ?? '',
      rewardId: data['reward_id'] as String? ?? '',
      localId: data['local_id'] as String?,
      status: data['status'] as String? ?? 'pending',
      starsSpent: data['stars_spent'] as int? ?? 0,
      requestedAt: data['requested_at'] == null
          ? null
          : DateTime.parse(data['requested_at'] as String),
      approvedAt: data['approved_at'] == null
          ? null
          : DateTime.parse(data['approved_at'] as String),
      rejectedAt: data['rejected_at'] == null
          ? null
          : DateTime.parse(data['rejected_at'] as String),
      cancelledAt: data['cancelled_at'] == null
          ? null
          : DateTime.parse(data['cancelled_at'] as String),
      note: data['note'] as String?,
      rejectionReason: data['rejection_reason'] as String?,
    );
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[ZeniRemoteRewardRequests] $message');
  }
}

class _SupabaseRewardRequestsTableClient
    implements ZeniRewardRequestsTableClient {
  const _SupabaseRewardRequestsTableClient(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchRewardRequests({
    required String familyId,
  }) async {
    final response = await _client
        .from('reward_requests')
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
        .from('reward_requests')
        .select()
        .eq('family_id', familyId)
        .eq('local_id', localId)
        .maybeSingle();
    return response;
  }

  @override
  Future<void> insertRewardRequest(Map<String, dynamic> payload) async {
    await _client.from('reward_requests').insert(payload);
  }

  @override
  Future<void> updateRewardRequest({
    required String rewardRequestId,
    required Map<String, dynamic> payload,
  }) async {
    await _client
        .from('reward_requests')
        .update(payload)
        .eq('id', rewardRequestId);
  }
}
