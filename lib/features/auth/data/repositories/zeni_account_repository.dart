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

class ZeniEnsureRemoteFamilyResult {
  const ZeniEnsureRemoteFamilyResult({
    required this.isSuccess,
    this.summary,
    this.message,
  });

  const ZeniEnsureRemoteFamilyResult.success(RemoteFamilySummary summary)
    : this(isSuccess: true, summary: summary);

  const ZeniEnsureRemoteFamilyResult.failure(String message)
    : this(isSuccess: false, message: message);

  final bool isSuccess;
  final RemoteFamilySummary? summary;
  final String? message;
}

class ZeniUpdateRemoteFamilyResult {
  const ZeniUpdateRemoteFamilyResult({
    required this.isSuccess,
    this.summary,
    this.message,
  });

  const ZeniUpdateRemoteFamilyResult.success(RemoteFamilySummary summary)
    : this(isSuccess: true, summary: summary);

  const ZeniUpdateRemoteFamilyResult.failure(String message)
    : this(isSuccess: false, message: message);

  final bool isSuccess;
  final RemoteFamilySummary? summary;
  final String? message;
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

  Future<ZeniEnsureRemoteFamilyResult> ensureRemoteFamilyForCurrentUser();

  Future<ZeniUpdateRemoteFamilyResult> updateRemoteFamilyName({
    required String familyId,
    required String name,
  });

  Future<ZeniDeleteAccountResult> deleteAccountAndRemoteFamily();
}
