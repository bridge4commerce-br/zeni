import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/child_profile.dart';
import 'remote_children_repository.dart';

abstract class ZeniChildrenTableClient {
  Future<Map<String, dynamic>?> findByFamilyAndLocalId({
    required String familyId,
    required String localId,
  });

  Future<void> insertChild(Map<String, dynamic> payload);

  Future<void> updateChild({
    required String childId,
    required Map<String, dynamic> payload,
  });

  Future<List<Map<String, dynamic>>> fetchChildren({required String familyId});
}

class SupabaseRemoteChildrenRepository implements RemoteChildrenRepository {
  SupabaseRemoteChildrenRepository({
    required SupabaseClient? client,
    ZeniChildrenTableClient? tableClient,
    String? currentUserIdOverride,
  }) : _client = client,
       _tableClient = tableClient ?? (client != null ? _SupabaseChildrenTableClient(client) : null),
       _currentUserIdOverride = currentUserIdOverride;

  final SupabaseClient? _client;
  final ZeniChildrenTableClient? _tableClient;
  final String? _currentUserIdOverride;

  @override
  bool get isConfigured => _tableClient != null;

  String? get _currentUserId =>
      _currentUserIdOverride ?? _client?.auth.currentUser?.id;

  @override
  Future<List<RemoteChildSummary>> getRemoteChildren({
    required String familyId,
  }) async {
    final tableClient = _tableClient;
    if (tableClient == null || _currentUserId == null) {
      return const <RemoteChildSummary>[];
    }

    try {
      final rows = await tableClient.fetchChildren(familyId: familyId);
      return rows.map(_parseChild).toList();
    } on PostgrestException catch (error) {
      _debugLog('getRemoteChildren error: ${error.message}');
      return const <RemoteChildSummary>[];
    } catch (error) {
      _debugLog('getRemoteChildren unexpected error: $error');
      return const <RemoteChildSummary>[];
    }
  }

  @override
  Future<ZeniEnsureRemoteChildrenResult> ensureRemoteChildren({
    required String familyId,
    required List<ChildProfile> localChildren,
  }) async {
    final tableClient = _tableClient;
    final currentUserId = _currentUserId;
    if (tableClient == null) {
      return const ZeniEnsureRemoteChildrenResult.failure(
        'Crianças remotas indisponíveis neste build.',
      );
    }

    if (currentUserId == null) {
      return const ZeniEnsureRemoteChildrenResult.failure(
        'Faça login para preparar as crianças na nuvem.',
      );
    }

    try {
      for (final child in localChildren) {
        final existing = await tableClient.findByFamilyAndLocalId(
          familyId: familyId,
          localId: child.id,
        );

        final payload = _buildPayload(
          child: child,
          familyId: familyId,
          existing: existing,
        );

        if (existing == null) {
          await tableClient.insertChild({
            ...payload,
            'created_by': currentUserId,
          });
        } else {
          await tableClient.updateChild(
            childId: existing['id'] as String,
            payload: payload,
          );
        }
      }

      final children = await getRemoteChildren(familyId: familyId);
      return ZeniEnsureRemoteChildrenResult.success(children);
    } on PostgrestException catch (error) {
      _debugLog('ensureRemoteChildren error: ${error.message}');
      return const ZeniEnsureRemoteChildrenResult.failure(
        'Não foi possível preparar as crianças na nuvem agora.',
      );
    } catch (error) {
      _debugLog('ensureRemoteChildren unexpected error: $error');
      return const ZeniEnsureRemoteChildrenResult.failure(
        'Não foi possível preparar as crianças na nuvem agora.',
      );
    }
  }

  Map<String, dynamic> _buildPayload({
    required ChildProfile child,
    required String familyId,
    required Map<String, dynamic>? existing,
  }) {
    final archivedAt = child.isActive
        ? null
        : (existing?['archived_at'] as String? ?? DateTime.now().toIso8601String());

    return {
      'family_id': familyId,
      'local_id': child.id,
      'name': child.name,
      'avatar_key': child.avatarUrl ?? child.emoji,
      'birth_date': child.birthDate?.toIso8601String().split('T').first,
      'archived_at': archivedAt,
    };
  }

  RemoteChildSummary _parseChild(Map<String, dynamic> data) {
    return RemoteChildSummary(
      id: data['id'] as String? ?? '',
      familyId: data['family_id'] as String? ?? '',
      localId: data['local_id'] as String?,
      name: data['name'] as String? ?? '',
      avatarKey: data['avatar_key'] as String?,
      birthDate: data['birth_date'] == null
          ? null
          : DateTime.parse(data['birth_date'] as String),
      archivedAt: data['archived_at'] == null
          ? null
          : DateTime.parse(data['archived_at'] as String),
    );
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[ZeniRemoteChildren] $message');
  }
}

class _SupabaseChildrenTableClient implements ZeniChildrenTableClient {
  const _SupabaseChildrenTableClient(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchChildren({
    required String familyId,
  }) async {
    final response = await _client
        .from('children')
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
        .from('children')
        .select()
        .eq('family_id', familyId)
        .eq('local_id', localId)
        .maybeSingle();
    return response;
  }

  @override
  Future<void> insertChild(Map<String, dynamic> payload) async {
    await _client.from('children').insert(payload);
  }

  @override
  Future<void> updateChild({
    required String childId,
    required Map<String, dynamic> payload,
  }) async {
    await _client.from('children').update(payload).eq('id', childId);
  }
}
