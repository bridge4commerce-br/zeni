import '../../../../core/domain/zeni_enums.dart';

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.familyId,
    required this.name,
    required this.role,
    required this.createdAt,
    this.email,
    this.childProfileId,
    this.isOwner = false,
  });

  final String id;
  final String familyId;
  final String name;
  final String? email;
  final ZeniUserRole role;
  final String? childProfileId;
  final bool isOwner;
  final DateTime createdAt;

  FamilyMember copyWith({
    String? id,
    String? familyId,
    String? name,
    String? email,
    ZeniUserRole? role,
    String? childProfileId,
    bool? isOwner,
    DateTime? createdAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      childProfileId: childProfileId ?? this.childProfileId,
      isOwner: isOwner ?? this.isOwner,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'familyId': familyId,
      'name': name,
      'email': email,
      'role': role.name,
      'childProfileId': childProfileId,
      'isOwner': isOwner,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      role: ZeniUserRole.values.byName(json['role'] as String),
      childProfileId: json['childProfileId'] as String?,
      isOwner: json['isOwner'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
