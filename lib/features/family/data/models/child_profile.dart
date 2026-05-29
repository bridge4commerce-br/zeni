class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.familyId,
    required this.name,
    required this.emoji,
    required this.starBalance,
    required this.streakCount,
    required this.createdAt,
    this.avatarUrl,
    this.birthDate,
    this.ttsEnabled = false,
    this.isActive = true,
  });

  final String id;
  final String familyId;
  final String name;
  final String emoji;
  final String? avatarUrl;
  final DateTime? birthDate;
  final int starBalance;
  final int streakCount;
  final bool ttsEnabled;
  final bool isActive;
  final DateTime createdAt;

  ChildProfile copyWith({
    String? id,
    String? familyId,
    String? name,
    String? emoji,
    String? avatarUrl,
    DateTime? birthDate,
    int? starBalance,
    int? streakCount,
    bool? ttsEnabled,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthDate: birthDate ?? this.birthDate,
      starBalance: starBalance ?? this.starBalance,
      streakCount: streakCount ?? this.streakCount,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'name': name,
      'emoji': emoji,
      'avatarUrl': avatarUrl,
      'birthDate': birthDate?.toIso8601String(),
      'starBalance': starBalance,
      'streakCount': streakCount,
      'ttsEnabled': ttsEnabled,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      birthDate: json['birthDate'] == null
          ? null
          : DateTime.parse(json['birthDate'] as String),
      starBalance: json['starBalance'] as int,
      streakCount: json['streakCount'] as int,
      ttsEnabled: json['ttsEnabled'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
