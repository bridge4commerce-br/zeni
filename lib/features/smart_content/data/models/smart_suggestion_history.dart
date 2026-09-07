enum SmartSuggestionContentType { mission, routine }

enum SmartSuggestionAction { viewed, accepted, rejected }

class SmartSuggestionHistory {
  const SmartSuggestionHistory({
    required this.childId,
    required this.contentId,
    required this.type,
    required this.action,
    required this.occurredAt,
  });

  final String childId;
  final String contentId;
  final SmartSuggestionContentType type;
  final SmartSuggestionAction action;
  final DateTime occurredAt;

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'contentId': contentId,
      'type': type.name,
      'action': action.name,
      'occurredAt': occurredAt.toIso8601String(),
    };
  }

  factory SmartSuggestionHistory.fromJson(Map<String, dynamic> json) {
    return SmartSuggestionHistory(
      childId: json['childId'] as String,
      contentId: json['contentId'] as String,
      type: SmartSuggestionContentType.values.byName(json['type'] as String),
      action: SmartSuggestionAction.values.byName(json['action'] as String),
      occurredAt: DateTime.parse(json['occurredAt'] as String),
    );
  }
}
