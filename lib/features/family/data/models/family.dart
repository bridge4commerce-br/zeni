class Family {
  const Family({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String inviteCode;
  final DateTime createdAt;

  Family copyWith({
    String? id,
    String? name,
    String? inviteCode,
    DateTime? createdAt,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'inviteCode': inviteCode,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['inviteCode'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
