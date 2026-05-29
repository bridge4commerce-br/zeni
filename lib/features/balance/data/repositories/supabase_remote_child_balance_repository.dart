import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'remote_child_balance_repository.dart';

abstract class ZeniChildStarBalancesViewClient {
  Future<List<Map<String, dynamic>>> fetchChildStarBalances({
    required String familyId,
  });
}

class SupabaseRemoteChildBalanceRepository
    implements RemoteChildBalanceRepository {
  SupabaseRemoteChildBalanceRepository({
    required SupabaseClient? client,
    ZeniChildStarBalancesViewClient? viewClient,
    String? currentUserIdOverride,
  }) : _client = client,
       _viewClient =
           viewClient ??
           (client != null
               ? _SupabaseChildStarBalancesViewClient(client)
               : null),
       _currentUserIdOverride = currentUserIdOverride;

  final SupabaseClient? _client;
  final ZeniChildStarBalancesViewClient? _viewClient;
  final String? _currentUserIdOverride;

  @override
  bool get isConfigured => _viewClient != null;

  String? get _currentUserId =>
      _currentUserIdOverride ?? _client?.auth.currentUser?.id;

  @override
  Future<List<RemoteChildStarBalance>> getRemoteChildStarBalances({
    required String familyId,
  }) async {
    final viewClient = _viewClient;
    if (viewClient == null || _currentUserId == null) {
      return const <RemoteChildStarBalance>[];
    }

    try {
      final rows = await viewClient.fetchChildStarBalances(familyId: familyId);
      return rows.map(_parseBalance).toList();
    } on PostgrestException catch (error) {
      _debugLog('getRemoteChildStarBalances error: ${error.message}');
      return const <RemoteChildStarBalance>[];
    } catch (error) {
      _debugLog('getRemoteChildStarBalances unexpected error: $error');
      return const <RemoteChildStarBalance>[];
    }
  }

  RemoteChildStarBalance _parseBalance(Map<String, dynamic> data) {
    return RemoteChildStarBalance(
      familyId: data['family_id'] as String? ?? '',
      childId: data['child_id'] as String? ?? '',
      childName: data['child_name'] as String? ?? '',
      creditsTotal: (data['credits_total'] as num?)?.toInt() ?? 0,
      debitsTotal: (data['debits_total'] as num?)?.toInt() ?? 0,
      derivedBalance: (data['derived_balance'] as num?)?.toInt() ?? 0,
      ledgerEventsCount: (data['ledger_events_count'] as num?)?.toInt() ?? 0,
      lastLedgerEventAt: data['last_ledger_event_at'] == null
          ? null
          : DateTime.parse(data['last_ledger_event_at'] as String),
    );
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[ZeniRemoteChildBalance] $message');
  }
}

class _SupabaseChildStarBalancesViewClient
    implements ZeniChildStarBalancesViewClient {
  const _SupabaseChildStarBalancesViewClient(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchChildStarBalances({
    required String familyId,
  }) async {
    final response = await _client
        .from('child_star_balances')
        .select()
        .eq('family_id', familyId)
        .order('child_name');
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }
}
