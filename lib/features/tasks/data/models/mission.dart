import '../../../../core/domain/zeni_enums.dart';

class Mission {
  const Mission({
    required this.id,
    required this.familyId,
    required this.childId,
    required this.title,
    required this.description,
    required this.stars,
    required this.recurrence,
    required this.timeGroup,
    required this.approvalMode,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.emoji = '✅',
    this.requiresPhoto = false,
    this.customDaysOfWeek = const <int>[],
  });

  static const List<int> fallbackCustomDaysOfWeek = <int>[
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  final String id;
  final String familyId;
  final String childId;
  final String title;
  final String description;
  final String emoji;
  final int stars;
  final MissionRecurrence recurrence;
  final MissionTimeGroup timeGroup;
  final MissionApprovalMode approvalMode;
  final MissionStatus status;
  final bool requiresPhoto;
  final List<int> customDaysOfWeek;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == MissionStatus.active;

  bool occursToday([DateTime? today]) {
    return occursOnDate(today ?? DateTime.now());
  }

  bool occursOnDate(DateTime date) {
    final normalizedDate = _dateOnly(date);
    final createdDate = _dateOnly(createdAt);

    return switch (recurrence) {
      MissionRecurrence.once => normalizedDate == createdDate,
      MissionRecurrence.daily => !normalizedDate.isBefore(createdDate),
      MissionRecurrence.weekdays =>
        !normalizedDate.isBefore(createdDate) &&
            normalizedDate.weekday >= DateTime.monday &&
            normalizedDate.weekday <= DateTime.friday,
      MissionRecurrence.weekends =>
        !normalizedDate.isBefore(createdDate) &&
            (normalizedDate.weekday == DateTime.saturday ||
                normalizedDate.weekday == DateTime.sunday),
      MissionRecurrence.customDaysOfWeek =>
        !normalizedDate.isBefore(createdDate) &&
            effectiveCustomDaysOfWeek.contains(normalizedDate.weekday),
    };
  }

  int remainingOccurrencesInMonth([DateTime? fromDate]) {
    final start = _dateOnly(fromDate ?? DateTime.now());
    final monthEnd = DateTime(start.year, start.month + 1, 0);
    var count = 0;

    for (
      var cursor = start;
      !cursor.isAfter(monthEnd);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      if (occursOnDate(cursor)) {
        count += 1;
      }
    }

    return count;
  }

  List<int> get effectiveCustomDaysOfWeek {
    final sanitized = _sanitizeCustomDaysOfWeek(customDaysOfWeek);
    if (recurrence == MissionRecurrence.customDaysOfWeek && sanitized.isEmpty) {
      return fallbackCustomDaysOfWeek;
    }

    return sanitized;
  }

  Mission copyWith({
    String? id,
    String? familyId,
    String? childId,
    String? title,
    String? description,
    String? emoji,
    int? stars,
    MissionRecurrence? recurrence,
    MissionTimeGroup? timeGroup,
    MissionApprovalMode? approvalMode,
    MissionStatus? status,
    bool? requiresPhoto,
    List<int>? customDaysOfWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Mission(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      childId: childId ?? this.childId,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      stars: stars ?? this.stars,
      recurrence: recurrence ?? this.recurrence,
      timeGroup: timeGroup ?? this.timeGroup,
      approvalMode: approvalMode ?? this.approvalMode,
      status: status ?? this.status,
      requiresPhoto: requiresPhoto ?? this.requiresPhoto,
      customDaysOfWeek: customDaysOfWeek ?? this.customDaysOfWeek,
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
      'stars': stars,
      'recurrence': recurrence.storageValue,
      'customDaysOfWeek': effectiveCustomDaysOfWeek,
      'timeGroup': timeGroup.name,
      'approvalMode': approvalMode.name,
      'status': status.name,
      'requiresPhoto': requiresPhoto,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    final recurrence = missionRecurrenceFromStorage(
      json['recurrence'] as String?,
    );
    final customDaysOfWeek = _parseCustomDaysOfWeek(
      json['customDaysOfWeek'] as List<dynamic>?,
    );

    return Mission(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      childId: json['childId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String? ?? '✅',
      stars: json['stars'] as int,
      recurrence: recurrence,
      timeGroup: MissionTimeGroup.values.byName(json['timeGroup'] as String),
      approvalMode: MissionApprovalMode.values.byName(
        json['approvalMode'] as String,
      ),
      status: MissionStatus.values.byName(json['status'] as String),
      requiresPhoto: json['requiresPhoto'] as bool? ?? false,
      customDaysOfWeek: recurrence == MissionRecurrence.customDaysOfWeek
          ? (customDaysOfWeek.isEmpty
                ? fallbackCustomDaysOfWeek
                : customDaysOfWeek)
          : const <int>[],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

List<int> _sanitizeCustomDaysOfWeek(List<int> days) {
  final sanitized =
      days
          .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
          .toSet()
          .toList()
        ..sort();
  return sanitized;
}

List<int> _parseCustomDaysOfWeek(List<dynamic>? rawDays) {
  if (rawDays == null) {
    return const <int>[];
  }

  return _sanitizeCustomDaysOfWeek(
    rawDays.whereType<num>().map((day) => day.toInt()).toList(),
  );
}
