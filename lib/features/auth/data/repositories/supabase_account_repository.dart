import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'zeni_account_repository.dart';

class SupabaseAccountRepository implements ZeniAccountRepository {
  SupabaseAccountRepository({required SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  @override
  bool get isConfigured => _client != null;

  @override
  Future<RemoteFamilySummary?> getCurrentRemoteFamilySummary() async {
    final client = _client;
    final currentUser = client?.auth.currentUser;
    if (client == null || currentUser == null) return null;

    try {
      final response = await client
          .from('family_members')
          .select('role, family:families!inner(id, name)')
          .eq('user_id', currentUser.id)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return _parseSummary(response);
    } on PostgrestException catch (error) {
      _debugLog('getCurrentRemoteFamilySummary error: ${error.message}');
      return null;
    } catch (error) {
      _debugLog('getCurrentRemoteFamilySummary unexpected error: $error');
      return null;
    }
  }

  @override
  Future<ZeniEnsureRemoteFamilyResult> ensureRemoteFamilyForCurrentUser() async {
    final client = _client;
    if (client == null) {
      return const ZeniEnsureRemoteFamilyResult.failure(
        'Conta remota indisponível neste build.',
      );
    }

    final currentUser = client.auth.currentUser;
    if (currentUser == null) {
      return const ZeniEnsureRemoteFamilyResult.failure(
        'Faça login para preparar a família remota.',
      );
    }

    try {
      final response = await client.rpc('ensure_user_family');
      final data = response as Map<String, dynamic>;
      return ZeniEnsureRemoteFamilyResult.success(_parseEnsureSummary(data));
    } on PostgrestException catch (error) {
      _debugLog('ensureRemoteFamilyForCurrentUser error: ${error.message}');
      return const ZeniEnsureRemoteFamilyResult.failure(
        'Não foi possível preparar a família remota agora.',
      );
    } catch (error) {
      _debugLog('ensureRemoteFamilyForCurrentUser unexpected error: $error');
      return const ZeniEnsureRemoteFamilyResult.failure(
        'Não foi possível preparar a família remota agora.',
      );
    }
  }

  @override
  Future<ZeniUpdateRemoteFamilyResult> updateRemoteFamilyName({
    required String familyId,
    required String name,
  }) async {
    final client = _client;
    final trimmedName = name.trim();
    if (client == null) {
      return const ZeniUpdateRemoteFamilyResult.failure(
        'Conta remota indisponível neste build.',
      );
    }

    if (client.auth.currentUser == null) {
      return const ZeniUpdateRemoteFamilyResult.failure(
        'Faça login para editar a família remota.',
      );
    }

    if (trimmedName.isEmpty) {
      return const ZeniUpdateRemoteFamilyResult.failure(
        'Digite um nome para a família.',
      );
    }

    try {
      await client
          .from('families')
          .update({'name': trimmedName})
          .eq('id', familyId);

      final refreshedSummary = await getCurrentRemoteFamilySummary();
      if (refreshedSummary == null) {
        return const ZeniUpdateRemoteFamilyResult.failure(
          'Não foi possível atualizar a família remota agora.',
        );
      }

      return ZeniUpdateRemoteFamilyResult.success(refreshedSummary);
    } on PostgrestException catch (error) {
      _debugLog('updateRemoteFamilyName error: ${error.message}');
      return const ZeniUpdateRemoteFamilyResult.failure(
        'Não foi possível atualizar a família remota agora.',
      );
    } catch (error) {
      _debugLog('updateRemoteFamilyName unexpected error: $error');
      return const ZeniUpdateRemoteFamilyResult.failure(
        'Não foi possível atualizar a família remota agora.',
      );
    }
  }

  RemoteFamilySummary _parseSummary(Map<String, dynamic> data) {
    final family = data['family'] as Map<String, dynamic>? ?? const {};
    return RemoteFamilySummary(
      familyId: family['id'] as String? ?? '',
      familyName: family['name'] as String? ?? 'Minha família',
      role: data['role'] as String? ?? 'owner',
    );
  }

  RemoteFamilySummary _parseEnsureSummary(Map<String, dynamic> data) {
    return RemoteFamilySummary(
      familyId: data['family_id'] as String? ?? '',
      familyName: data['family_name'] as String? ?? 'Minha família',
      role: data['role'] as String? ?? 'owner',
      email: data['email'] as String?,
    );
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[ZeniAccount] $message');
  }
}
