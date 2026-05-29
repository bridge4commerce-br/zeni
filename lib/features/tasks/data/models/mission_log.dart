import '../../../../core/domain/zeni_enums.dart';

class MissionLog {
  const MissionLog({
    required this.id,
    required this.missionId,
    required this.childId,
    required this.scheduledDate,
    required this.status,
    required this.starsAwarded,
    this.completedAt,
    this.approvedAt,
    this.rejectedAt,
    this.photoUrl,
    this.note,
  });

  final String id;
  final String missionId;
  final String childId;
  final DateTime scheduledDate;
  final MissionLogStatus status;
  final int starsAwarded;
  final DateTime? completedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? photoUrl;
  final String? note;

  bool get isPending => status == MissionLogStatus.pending;

  bool get isAwaitingApproval => status == MissionLogStatus.awaitingApproval;

  bool get isApproved => status == MissionLogStatus.approved;

  MissionLog copyWith({
    String? id,
    String? missionId,
    String? childId,
    DateTime? scheduledDate,
    MissionLogStatus? status,
    int? starsAwarded,
    DateTime? completedAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? photoUrl,
    String? note,
  }) {
    return MissionLog(
      id: id ?? this.id,
      missionId: missionId ?? this.missionId,
      childId: childId ?? this.childId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      starsAwarded: starsAwarded ?? this.starsAwarded,
      completedAt: completedAt ?? this.completedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      photoUrl: photoUrl ?? this.photoUrl,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'missionId': missionId,
      'childId': childId,
      'scheduledDate': scheduledDate.toIso8601String(),
      'status': status.name,
      'starsAwarded': starsAwarded,
      'completedAt': completedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'photoUrl': photoUrl,
      'note': note,
    };
  }

  factory MissionLog.fromJson(Map<String, dynamic> json) {
    return MissionLog(
      id: json['id'] as String,
      missionId: json['missionId'] as String,
      childId: json['childId'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      status: MissionLogStatus.values.byName(json['status'] as String),
      starsAwarded: json['starsAwarded'] as int,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      approvedAt: json['approvedAt'] == null
          ? null
          : DateTime.parse(json['approvedAt'] as String),
      rejectedAt: json['rejectedAt'] == null
          ? null
          : DateTime.parse(json['rejectedAt'] as String),
      photoUrl: json['photoUrl'] as String?,
      note: json['note'] as String?,
    );
  }
}
