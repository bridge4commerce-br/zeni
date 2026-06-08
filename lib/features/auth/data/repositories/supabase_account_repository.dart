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

  @override
  Future<ZeniDeleteAccountResult> deleteAccountAndRemoteFamily() async {
    final client = _client;
    if (client == null) {
      return const ZeniDeleteAccountResult.failure(
        message: 'Conta remota indisponível neste build.',
        errorCode: 'not_available',
      );
    }

    if (client.auth.currentUser == null) {
      return const ZeniDeleteAccountResult.failure(
        message: 'Faça login para excluir conta e dados da nuvem.',
        errorCode: 'not_authenticated',
      );
    }

    try {
      final response = await client.functions.invoke(
        'delete-account',
        body: const <String, dynamic>{},
      );
      final data = response.data as Map<String, dynamic>? ?? const {};
      return _parseDeleteAccountResult(data);
    } on FunctionException catch (error) {
      _debugLog('deleteAccountAndRemoteFamily error: ${error.details}');
      final details = error.details;
      if (details is Map<String, dynamic>) {
        return _parseDeleteAccountResult(details);
      }

      return const ZeniDeleteAccountResult.failure(
        message: 'Não foi possível excluir conta e dados da nuvem agora.',
        errorCode: 'unexpected_error',
      );
    } catch (error) {
      _debugLog('deleteAccountAndRemoteFamily unexpected error: $error');
      return const ZeniDeleteAccountResult.failure(
        message: 'Não foi possível excluir conta e dados da nuvem agora.',
        errorCode: 'unexpected_error',
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

  ZeniDeleteAccountResult _parseDeleteAccountResult(Map<String, dynamic> data) {
    final isSuccess = data['success'] == true;
    final familyId = data['family_id'] as String?;
    final message = data['message'] as String?;
    final errorCode = data['error_code'] as String?;
    if (isSuccess) {
      return ZeniDeleteAccountResult.success(
        familyId: familyId,
        message: message ?? 'Sua conta e os dados da família foram removidos da nuvem.',
      );
    }

    return ZeniDeleteAccountResult.failure(
      familyId: familyId,
      message: message ?? _messageForDeleteErrorCode(errorCode),
      errorCode: errorCode ?? 'unexpected_error',
    );
  }

  String _messageForDeleteErrorCode(String? errorCode) {
    return switch (errorCode) {
      'not_authenticated' => 'Faça login para excluir conta e dados da nuvem.',
      'not_owner' =>
        'Apenas o responsável principal pode excluir a família da nuvem.',
      'family_has_multiple_members' =>
        'Esta família possui mais de um responsável. A exclusão completa ainda não está disponível neste caso.',
      'no_family' => 'Nenhuma família remota foi encontrada para esta conta.',
      'auth_delete_failed' =>
        'Os dados da família foram removidos, mas não foi possível finalizar a exclusão da conta. Entre em contato com o suporte.',
      _ => 'Não foi possível excluir conta e dados da nuvem agora.',
    };
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[ZeniAccount] $message');
  }
}
