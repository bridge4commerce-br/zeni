import '../../../../core/domain/zeni_enums.dart';

class StarLedgerEntry {
  const StarLedgerEntry({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.amount,
    required this.balanceAfter,
    required this.type,
    required this.title,
    required this.createdAt,
    this.description,
    this.relatedMissionLogId,
    this.relatedRewardRequestId,
  });

  final String id;
  final String familyId;
  final String childId;
  final int amount;
  final int balanceAfter;
  final StarLedgerEntryType type;
  final String title;
  final String? description;
  final DateTime createdAt;
  final String? relatedMissionLogId;
  final String? relatedRewardRequestId;

  bool get isPositive => amount > 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'childId': childId,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'type': type.name,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'relatedMissionLogId': relatedMissionLogId,
      'relatedRewardRequestId': relatedRewardRequestId,
    };
  }

  factory StarLedgerEntry.fromJson(Map<String, dynamic> json) {
    return StarLedgerEntry(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      childId: json['childId'] as String,
      amount: json['amount'] as int,
      balanceAfter: json['balanceAfter'] as int,
      type: StarLedgerEntryType.values.byName(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      relatedMissionLogId: json['relatedMissionLogId'] as String?,
      relatedRewardRequestId: json['relatedRewardRequestId'] as String?,
    );
  }
}
