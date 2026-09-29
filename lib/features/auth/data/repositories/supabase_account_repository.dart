import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'zeni_account_repository.dart';

class SupabaseAccountRepository implements ZeniAccountRepository {
  SupabaseAccountRepository({required SupabaseClient? client})
    : _client = client;

  final SupabaseClient? _client;

  @override
  bool get isConfigured => _client != null;

  @override
  Future<ZeniResolveCurrentFamilyResult> resolveCurrentFamily() async {
    final client = _client;
    final currentUser = client?.auth.currentUser;
    if (client == null) {
      return const ZeniResolveCurrentFamilyResult.failure(
        'Conta remota indisponível neste build.',
      );
    }
    if (currentUser == null) {
      return const ZeniResolveCurrentFamilyResult.failure(
        'Faça login para identificar a família remota.',
      );
    }

    try {
      final response = await client.rpc('resolve_current_family');
      if (client.auth.currentUser?.id != currentUser.id) {
        return const ZeniResolveCurrentFamilyResult.failure(
          canonicalFamilySessionChangedMessage,
        );
      }
      return _parseResolveResult(response as Map<String, dynamic>);
    } on PostgrestException catch (error) {
      _debugLog('resolveCurrentFamily error: ${error.message}');
      return const ZeniResolveCurrentFamilyResult.failure(
        'Não foi possível identificar a família remota agora.',
      );
    } catch (error) {
      _debugLog('resolveCurrentFamily unexpected error: $error');
      return const ZeniResolveCurrentFamilyResult.failure(
        'A resposta de identificação da família remota é inválida.',
      );
    }
  }

  @override
  Future<ZeniCreateInitialFamilyResult> createInitialFamily() async {
    final client = _client;
    final currentUser = client?.auth.currentUser;
    if (client == null) {
      return const ZeniCreateInitialFamilyResult.failure(
        'Conta remota indisponível neste build.',
      );
    }
    if (currentUser == null) {
      return const ZeniCreateInitialFamilyResult.failure(
        'Faça login para criar a família remota.',
      );
    }

    try {
      final response = await client.rpc('create_initial_family');
      if (client.auth.currentUser?.id != currentUser.id) {
        return const ZeniCreateInitialFamilyResult.failure(
          canonicalFamilySessionChangedMessage,
        );
      }
      return _parseCreateResult(response as Map<String, dynamic>);
    } on PostgrestException catch (error) {
      _debugLog('createInitialFamily error: ${error.message}');
      return const ZeniCreateInitialFamilyResult.failure(
        'Não foi possível criar a família remota agora.',
      );
    } catch (error) {
      _debugLog('createInitialFamily unexpected error: $error');
      return const ZeniCreateInitialFamilyResult.failure(
        'A resposta de criação da família remota é inválida.',
      );
    }
  }

  @override
  Future<RemoteFamilySummary?> getCurrentRemoteFamilySummary() async {
    final result = await resolveCurrentFamily();
    return result.status == ZeniResolveCurrentFamilyStatus.found
        ? result.summary
        : null;
  }

  @override
  Future<ZeniAccountProfile?> getCurrentAccountProfile() async {
    final client = _client;
    final currentUser = client?.auth.currentUser;
    if (client == null || currentUser == null) return null;

    try {
      final data = await client
          .from('profiles')
          .select('id, email, display_name')
          .eq('id', currentUser.id)
          .maybeSingle();
      return data == null ? null : _parseAccountProfile(data);
    } on PostgrestException catch (error) {
      _debugLog('getCurrentAccountProfile error: ${error.message}');
      return null;
    } catch (error) {
      _debugLog('getCurrentAccountProfile unexpected error: $error');
      return null;
    }
  }

  @override
  Future<ZeniUpdateAccountProfileResult> initializeCurrentAccountProfile({
    String? suggestedDisplayName,
  }) async {
    final client = _client;
    final currentUser = client?.auth.currentUser;
    if (client == null) {
      return const ZeniUpdateAccountProfileResult.failure(
        'Conta remota indisponível neste build.',
      );
    }
    if (currentUser == null) {
      return const ZeniUpdateAccountProfileResult.failure(
        'Faça login para carregar seu perfil.',
      );
    }

    final existing = await getCurrentAccountProfile();
    if (existing != null && existing.displayName.trim().isNotEmpty) {
      return ZeniUpdateAccountProfileResult.success(existing);
    }

    final candidate = suggestedDisplayName?.trim() ?? '';
    if (candidate.isEmpty) {
      return const ZeniUpdateAccountProfileResult.failure(
        'O perfil ainda não possui um nome.',
      );
    }

    try {
      if (existing == null) {
        await client
            .from('profiles')
            .upsert(
              {
                'id': currentUser.id,
                'email': currentUser.email,
                'display_name': candidate,
              },
              onConflict: 'id',
              ignoreDuplicates: true,
            );
      } else {
        await client
            .from('profiles')
            .update({'display_name': candidate})
            .eq('id', currentUser.id)
            .isFilter('display_name', null);
      }
      final profile = await getCurrentAccountProfile();
      if (profile == null) {
        return const ZeniUpdateAccountProfileResult.failure(
          'Não foi possível carregar seu perfil agora.',
        );
      }
      return ZeniUpdateAccountProfileResult.success(profile);
    } on PostgrestException catch (error) {
      _debugLog('initializeCurrentAccountProfile error: ${error.message}');
      return const ZeniUpdateAccountProfileResult.failure(
        'Não foi possível preparar seu perfil agora.',
      );
    } catch (error) {
      _debugLog('initializeCurrentAccountProfile unexpected error: $error');
      return const ZeniUpdateAccountProfileResult.failure(
        'Não foi possível preparar seu perfil agora.',
      );
    }
  }

  @override
  Future<ZeniUpdateAccountProfileResult> updateCurrentAccountDisplayName({
    required String displayName,
  }) async {
    final client = _client;
    final currentUser = client?.auth.currentUser;
    final trimmedName = displayName.trim();
    if (client == null) {
      return const ZeniUpdateAccountProfileResult.failure(
        'Conta remota indisponível neste build.',
      );
    }
    if (currentUser == null) {
      return const ZeniUpdateAccountProfileResult.failure(
        'Faça login para editar seu nome.',
      );
    }
    if (trimmedName.isEmpty) {
      return const ZeniUpdateAccountProfileResult.failure('Informe seu nome.');
    }

    try {
      final data = await client
          .from('profiles')
          .update({'display_name': trimmedName})
          .eq('id', currentUser.id)
          .select('id, email, display_name')
          .single();
      return ZeniUpdateAccountProfileResult.success(_parseAccountProfile(data));
    } on PostgrestException catch (error) {
      _debugLog('updateCurrentAccountDisplayName error: ${error.message}');
      return const ZeniUpdateAccountProfileResult.failure(
        'Não foi possível atualizar seu nome agora.',
      );
    } catch (error) {
      _debugLog('updateCurrentAccountDisplayName unexpected error: $error');
      return const ZeniUpdateAccountProfileResult.failure(
        'Não foi possível atualizar seu nome agora.',
      );
    }
  }

  @override
  Future<ZeniUpdateRemoteFamilyResult> updateRemoteFamilyName({
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
      final response = await client.rpc(
        'rename_current_family',
        params: {'p_name': trimmedName},
      );
      return ZeniUpdateRemoteFamilyResult.fromRpcResponse(response);
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

  ZeniResolveCurrentFamilyResult _parseResolveResult(
    Map<String, dynamic> data,
  ) {
    _validateContract(data);
    final userId = data['user_id'] as String;
    return switch (data['status']) {
      'found' => ZeniResolveCurrentFamilyResult.found(
        summary: _parseCanonicalSummary(data),
        userId: userId,
        membershipId: data['membership_id'] as String,
      ),
      'not_found' => ZeniResolveCurrentFamilyResult.notFound(userId: userId),
      'ambiguous' => ZeniResolveCurrentFamilyResult.ambiguous(
        userId: userId,
        reason: data['reason'] as String?,
      ),
      'inconsistent' => ZeniResolveCurrentFamilyResult.inconsistent(
        userId: userId,
        reason: data['reason'] as String?,
      ),
      _ => throw const FormatException('unknown resolve status'),
    };
  }

  ZeniCreateInitialFamilyResult _parseCreateResult(Map<String, dynamic> data) {
    _validateContract(data);
    final userId = data['user_id'] as String;
    return switch (data['status']) {
      'created' => ZeniCreateInitialFamilyResult.created(
        summary: _parseCanonicalSummary(data),
        userId: userId,
        membershipId: data['membership_id'] as String,
      ),
      'already_exists' => ZeniCreateInitialFamilyResult.alreadyExists(
        summary: _parseCanonicalSummary(data),
        userId: userId,
        membershipId: data['membership_id'] as String,
      ),
      'ambiguous' => ZeniCreateInitialFamilyResult.ambiguous(
        userId: userId,
        reason: data['reason'] as String?,
      ),
      'inconsistent' => ZeniCreateInitialFamilyResult.inconsistent(
        userId: userId,
        reason: data['reason'] as String?,
      ),
      _ => throw const FormatException('unknown create status'),
    };
  }

  void _validateContract(Map<String, dynamic> data) {
    if (data['contract_version'] != 1 ||
        data['status'] is! String ||
        data['user_id'] is! String) {
      throw const FormatException('invalid canonical family contract');
    }
  }

  RemoteFamilySummary _parseCanonicalSummary(Map<String, dynamic> data) {
    final familyId = data['family_id'];
    final familyName = data['family_name'];
    final role = data['role'];
    final membershipId = data['membership_id'];
    if (familyId is! String ||
        familyName is! String ||
        role is! String ||
        membershipId is! String) {
      throw const FormatException('incomplete canonical family summary');
    }
    return RemoteFamilySummary(
      familyId: familyId,
      familyName: familyName,
      role: role,
    );
  }

  ZeniAccountProfile _parseAccountProfile(Map<String, dynamic> data) {
    final userId = data['id'];
    final displayName = data['display_name'];
    if (userId is! String || (displayName != null && displayName is! String)) {
      throw const FormatException('incomplete account profile');
    }
    return ZeniAccountProfile(
      userId: userId,
      displayName: (displayName as String?)?.trim() ?? '',
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
        message:
            message ??
            'Sua conta e os dados da família foram removidos da nuvem.',
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
