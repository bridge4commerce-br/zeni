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

abstract class ZeniAccountRepository {
  bool get isConfigured;

  Future<RemoteFamilySummary?> getCurrentRemoteFamilySummary();

  Future<ZeniEnsureRemoteFamilyResult> ensureRemoteFamilyForCurrentUser();

  Future<ZeniUpdateRemoteFamilyResult> updateRemoteFamilyName({
    required String familyId,
    required String name,
  });
}
