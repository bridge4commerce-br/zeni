import '../models/child_profile.dart';

class RemoteChildSummary {
  const RemoteChildSummary({
    required this.id,
    required this.familyId,
    required this.localId,
    required this.name,
    required this.avatarKey,
    this.birthDate,
    this.archivedAt,
  });

  final String id;
  final String familyId;
  final String? localId;
  final String name;
  final String? avatarKey;
  final DateTime? birthDate;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;
}

class ZeniEnsureRemoteChildrenResult {
  const ZeniEnsureRemoteChildrenResult({
    required this.isSuccess,
    this.children = const <RemoteChildSummary>[],
    this.message,
  });

  const ZeniEnsureRemoteChildrenResult.success(List<RemoteChildSummary> children)
    : this(isSuccess: true, children: children);

  const ZeniEnsureRemoteChildrenResult.failure(String message)
    : this(isSuccess: false, message: message);

  final bool isSuccess;
  final List<RemoteChildSummary> children;
  final String? message;
}

abstract class RemoteChildrenRepository {
  bool get isConfigured;

  Future<List<RemoteChildSummary>> getRemoteChildren({required String familyId});

  Future<ZeniEnsureRemoteChildrenResult> ensureRemoteChildren({
    required String familyId,
    required List<ChildProfile> localChildren,
  });
}
