import '../../../../core/domain/zeni_enums.dart';

class Reward {
  const Reward({
    required this.id,
    required this.familyId,
    required this.title,
    required this.description,
    required this.cost,
    required this.renewal,
    required this.createdAt,
    required this.updatedAt,
    this.childId,
    this.emoji = '🎁',
    this.isActive = true,
  });

  final String id;
  final String familyId;
  final String? childId;
  final String title;
  final String description;
  final String emoji;
  final int cost;
  final RewardRenewal renewal;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reward copyWith({
    String? id,
    String? familyId,
    String? childId,
    String? title,
    String? description,
    String? emoji,
    int? cost,
    RewardRenewal? renewal,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reward(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      childId: childId ?? this.childId,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      cost: cost ?? this.cost,
      renewal: renewal ?? this.renewal,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'childId': childId,
      'title': title,
      'description': description,
      'emoji': emoji,
      'cost': cost,
      'renewal': renewal.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      childId: json['childId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String? ?? '🎁',
      cost: json['cost'] as int,
      renewal: RewardRenewal.values.byName(json['renewal'] as String),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
