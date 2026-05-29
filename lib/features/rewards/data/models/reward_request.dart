import '../../../../core/domain/zeni_enums.dart';

class RewardRequest {
  const RewardRequest({
    required this.id,
    required this.rewardId,
    required this.childId,
    required this.status,
    required this.requestedAt,
    this.resolvedAt,
    this.note,
  });

  final String id;
  final String rewardId;
  final String childId;
  final RewardRequestStatus status;
  final DateTime requestedAt;
  final DateTime? resolvedAt;
  final String? note;

  bool get isPending => status == RewardRequestStatus.pending;

  RewardRequest copyWith({
    String? id,
    String? rewardId,
    String? childId,
    RewardRequestStatus? status,
    DateTime? requestedAt,
    DateTime? resolvedAt,
    String? note,
  }) {
    return RewardRequest(
      id: id ?? this.id,
      rewardId: rewardId ?? this.rewardId,
      childId: childId ?? this.childId,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rewardId': rewardId,
      'childId': childId,
      'status': status.name,
      'requestedAt': requestedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'note': note,
    };
  }

  factory RewardRequest.fromJson(Map<String, dynamic> json) {
    return RewardRequest(
      id: json['id'] as String,
      rewardId: json['rewardId'] as String,
      childId: json['childId'] as String,
      status: RewardRequestStatus.values.byName(json['status'] as String),
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      note: json['note'] as String?,
    );
  }
}
