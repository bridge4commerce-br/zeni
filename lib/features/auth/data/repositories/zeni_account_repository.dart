class RemoteFamilySummary {
  const RemoteFamilySummary({
    required this.familyId,
    required this.familyName,
    required this.role,
    this.email,
  });

  final String familyId;
  final String familyName;
  final String role;
  final String? email;

  String get roleLabel => switch (role) {
    'owner' => 'Responsável principal',
    'responsible' => 'Responsável',
    _ => 'Responsável',
  };
}

class ZeniAccountProfile {
  const ZeniAccountProfile({
    required this.userId,
    required this.displayName,
    this.email,
  });

  final String userId;
  final String displayName;
  final String? email;
}

class ZeniUpdateAccountProfileResult {
  const ZeniUpdateAccountProfileResult({
    required this.isSuccess,
    this.profile,
    this.message,
  });

  const ZeniUpdateAccountProfileResult.success(ZeniAccountProfile profile)
    : this(isSuccess: true, profile: profile);

  const ZeniUpdateAccountProfileResult.failure(String message)
    : this(isSuccess: false, message: message);

  final bool isSuccess;
  final ZeniAccountProfile? profile;
  final String? message;
}

enum ZeniResolveCurrentFamilyStatus {
  found,
  notFound,
  ambiguous,
  inconsistent,
  failure,
}

class ZeniResolveCurrentFamilyResult {
  const ZeniResolveCurrentFamilyResult({
    required this.status,
    this.summary,
    this.userId,
    this.membershipId,
    this.reason,
    this.message,
  });

  const ZeniResolveCurrentFamilyResult.found({
    required RemoteFamilySummary summary,
    required String userId,
    required String membershipId,
  }) : this(
         status: ZeniResolveCurrentFamilyStatus.found,
         summary: summary,
         userId: userId,
         membershipId: membershipId,
       );

  const ZeniResolveCurrentFamilyResult.notFound({required String userId})
    : this(status: ZeniResolveCurrentFamilyStatus.notFound, userId: userId);

  const ZeniResolveCurrentFamilyResult.ambiguous({
    required String userId,
    String? reason,
  }) : this(
         status: ZeniResolveCurrentFamilyStatus.ambiguous,
         userId: userId,
         reason: reason,
       );

  const ZeniResolveCurrentFamilyResult.inconsistent({
    required String userId,
    String? reason,
  }) : this(
         status: ZeniResolveCurrentFamilyStatus.inconsistent,
         userId: userId,
         reason: reason,
       );

  const ZeniResolveCurrentFamilyResult.failure(String message)
    : this(status: ZeniResolveCurrentFamilyStatus.failure, message: message);

  final ZeniResolveCurrentFamilyStatus status;
  final RemoteFamilySummary? summary;
  final String? userId;
  final String? membershipId;
  final String? reason;
  final String? message;
}

enum ZeniCreateInitialFamilyStatus {
  created,
  alreadyExists,
  ambiguous,
  inconsistent,
  failure,
}

class ZeniCreateInitialFamilyResult {
  const ZeniCreateInitialFamilyResult({
    required this.status,
    this.summary,
    this.userId,
    this.membershipId,
    this.reason,
    this.message,
  });

  const ZeniCreateInitialFamilyResult.created({
    required RemoteFamilySummary summary,
    required String userId,
    required String membershipId,
  }) : this(
         status: ZeniCreateInitialFamilyStatus.created,
         summary: summary,
         userId: userId,
         membershipId: membershipId,
       );

  const ZeniCreateInitialFamilyResult.alreadyExists({
    required RemoteFamilySummary summary,
    required String userId,
    required String membershipId,
  }) : this(
         status: ZeniCreateInitialFamilyStatus.alreadyExists,
         summary: summary,
         userId: userId,
         membershipId: membershipId,
       );

  const ZeniCreateInitialFamilyResult.ambiguous({
    required String userId,
    String? reason,
  }) : this(
         status: ZeniCreateInitialFamilyStatus.ambiguous,
         userId: userId,
         reason: reason,
       );

  const ZeniCreateInitialFamilyResult.inconsistent({
    required String userId,
    String? reason,
  }) : this(
         status: ZeniCreateInitialFamilyStatus.inconsistent,
         userId: userId,
         reason: reason,
       );

  const ZeniCreateInitialFamilyResult.failure(String message)
    : this(status: ZeniCreateInitialFamilyStatus.failure, message: message);

  final ZeniCreateInitialFamilyStatus status;
  final RemoteFamilySummary? summary;
  final String? userId;
  final String? membershipId;
  final String? reason;
  final String? message;
}

const canonicalFamilyAmbiguousMessage =
    'A conta possui mais de uma família remota. O acesso à nuvem foi bloqueado.';
const canonicalFamilyInconsistentMessage =
    'A identidade da família remota está inconsistente. O acesso à nuvem foi bloqueado.';
const canonicalFamilyPendingMessage =
    'Existem dados locais não vinculados. A família remota não foi criada automaticamente.';
const canonicalFamilySessionChangedMessage =
    'A sessão mudou durante a preparação da família. Tente entrar novamente.';

enum ZeniUpdateRemoteFamilyStatus {
  updated,
  notFound,
  ambiguous,
  inconsistent,
  forbidden,
  invalidName,
  failure,
}

class ZeniUpdateRemoteFamilyResult {
  const ZeniUpdateRemoteFamilyResult({
    required this.status,
    this.summary,
    this.membershipId,
    this.reason,
    this.updatedAt,
    this.message,
  });

  const ZeniUpdateRemoteFamilyResult.success(
    RemoteFamilySummary summary, {
    String? membershipId,
    DateTime? updatedAt,
  }) : this(
         status: ZeniUpdateRemoteFamilyStatus.updated,
         summary: summary,
         membershipId: membershipId,
         updatedAt: updatedAt,
       );

  const ZeniUpdateRemoteFamilyResult.failure(String message)
    : this(status: ZeniUpdateRemoteFamilyStatus.failure, message: message);

  factory ZeniUpdateRemoteFamilyResult.fromRpcResponse(Object? response) {
    const malformedMessage =
        'A resposta de atualização da família remota é inválida.';
    if (response is! Map<String, dynamic> ||
        response['contract_version'] != 1 ||
        response['status'] is! String ||
        !response.containsKey('reason') ||
        !response.containsKey('family_id') ||
        !response.containsKey('membership_id') ||
        !response.containsKey('family_name') ||
        !response.containsKey('role') ||
        !response.containsKey('updated_at')) {
      return const ZeniUpdateRemoteFamilyResult.failure(malformedMessage);
    }

    final status = response['status'] as String;
    final reason = response['reason'];
    final familyIdValue = response['family_id'];
    final membershipIdValue = response['membership_id'];
    final familyNameValue = response['family_name'];
    final roleValue = response['role'];
    final updatedAtValue = response['updated_at'];
    if ((reason != null && reason is! String) ||
        (familyIdValue != null && familyIdValue is! String) ||
        (membershipIdValue != null && membershipIdValue is! String) ||
        (familyNameValue != null && familyNameValue is! String) ||
        (roleValue != null && roleValue is! String) ||
        (updatedAtValue != null &&
            (updatedAtValue is! String ||
                DateTime.tryParse(updatedAtValue) == null))) {
      return const ZeniUpdateRemoteFamilyResult.failure(malformedMessage);
    }

    if (status == 'updated') {
      final familyId = familyIdValue;
      final membershipId = membershipIdValue;
      final familyName = familyNameValue;
      final role = roleValue;
      final updatedAt = updatedAtValue is String
          ? DateTime.tryParse(updatedAtValue)
          : null;
      if (familyId is! String ||
          membershipId is! String ||
          familyName is! String ||
          familyName.trim().isEmpty ||
          role != 'owner' ||
          updatedAt == null) {
        return const ZeniUpdateRemoteFamilyResult.failure(malformedMessage);
      }
      return ZeniUpdateRemoteFamilyResult.success(
        RemoteFamilySummary(
          familyId: familyId,
          familyName: familyName,
          role: role as String,
        ),
        membershipId: membershipId,
        updatedAt: updatedAt,
      );
    }

    final mappedStatus = switch (status) {
      'not_found' => ZeniUpdateRemoteFamilyStatus.notFound,
      'ambiguous' => ZeniUpdateRemoteFamilyStatus.ambiguous,
      'inconsistent' => ZeniUpdateRemoteFamilyStatus.inconsistent,
      'forbidden' => ZeniUpdateRemoteFamilyStatus.forbidden,
      'invalid_name' => ZeniUpdateRemoteFamilyStatus.invalidName,
      _ => null,
    };
    if (mappedStatus == null) {
      return const ZeniUpdateRemoteFamilyResult.failure(malformedMessage);
    }

    return ZeniUpdateRemoteFamilyResult(
      status: mappedStatus,
      reason: reason as String?,
      message: switch (mappedStatus) {
        ZeniUpdateRemoteFamilyStatus.notFound =>
          'Não foi possível localizar a família desta conta.',
        ZeniUpdateRemoteFamilyStatus.ambiguous =>
          canonicalFamilyAmbiguousMessage,
        ZeniUpdateRemoteFamilyStatus.inconsistent =>
          canonicalFamilyInconsistentMessage,
        ZeniUpdateRemoteFamilyStatus.forbidden =>
          'Apenas o responsável principal pode alterar o nome da família.',
        ZeniUpdateRemoteFamilyStatus.invalidName =>
          'Use um nome entre 1 e 80 caracteres, sem caracteres de controle.',
        _ => malformedMessage,
      },
    );
  }

  final ZeniUpdateRemoteFamilyStatus status;
  final RemoteFamilySummary? summary;
  final String? membershipId;
  final String? reason;
  final DateTime? updatedAt;
  final String? message;

  bool get isSuccess => status == ZeniUpdateRemoteFamilyStatus.updated;
}

class ZeniDeleteAccountResult {
  const ZeniDeleteAccountResult({
    required this.isSuccess,
    this.familyId,
    this.message,
    this.errorCode,
  });

  const ZeniDeleteAccountResult.success({String? familyId, String? message})
    : this(isSuccess: true, familyId: familyId, message: message);

  const ZeniDeleteAccountResult.failure({
    String? familyId,
    String? message,
    String? errorCode,
  }) : this(
         isSuccess: false,
         familyId: familyId,
         message: message,
         errorCode: errorCode,
       );

  final bool isSuccess;
  final String? familyId;
  final String? message;
  final String? errorCode;
}

abstract class ZeniAccountRepository {
  const ZeniAccountRepository();

  bool get isConfigured;

  Future<ZeniResolveCurrentFamilyResult> resolveCurrentFamily();

  Future<ZeniCreateInitialFamilyResult> createInitialFamily();

  Future<RemoteFamilySummary?> getCurrentRemoteFamilySummary();

  Future<ZeniAccountProfile?> getCurrentAccountProfile() async => null;

  Future<ZeniUpdateAccountProfileResult> initializeCurrentAccountProfile({
    String? suggestedDisplayName,
  }) async => const ZeniUpdateAccountProfileResult.failure(
    'Perfil remoto indisponível.',
  );

  Future<ZeniUpdateAccountProfileResult> updateCurrentAccountDisplayName({
    required String displayName,
  }) async => const ZeniUpdateAccountProfileResult.failure(
    'Perfil remoto indisponível.',
  );

  Future<ZeniUpdateRemoteFamilyResult> updateRemoteFamilyName({
    required String name,
  });

  Future<ZeniDeleteAccountResult> deleteAccountAndRemoteFamily();
}
