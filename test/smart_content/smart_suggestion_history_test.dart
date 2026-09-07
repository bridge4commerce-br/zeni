import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/features/smart_content/data/models/smart_suggestion_history.dart';

void main() {
  group('SmartSuggestionHistory', () {
    test('serializa e restaura o histórico local', () {
      final occurredAt = DateTime.utc(2026, 9, 7, 15, 30);

      final history = SmartSuggestionHistory(
        childId: 'child-1',
        contentId: 'brush_teeth',
        type: SmartSuggestionContentType.mission,
        action: SmartSuggestionAction.accepted,
        occurredAt: occurredAt,
      );

      final restored = SmartSuggestionHistory.fromJson(history.toJson());

      expect(restored.childId, 'child-1');
      expect(restored.contentId, 'brush_teeth');
      expect(restored.type, SmartSuggestionContentType.mission);
      expect(restored.action, SmartSuggestionAction.accepted);
      expect(restored.occurredAt, occurredAt);
    });

    test('usa valores estáveis para tipo e ação', () {
      final history = SmartSuggestionHistory(
        childId: 'child-1',
        contentId: 'after_school',
        type: SmartSuggestionContentType.routine,
        action: SmartSuggestionAction.viewed,
        occurredAt: DateTime.utc(2026, 9, 7),
      );

      final json = history.toJson();

      expect(json['type'], 'routine');
      expect(json['action'], 'viewed');
    });

    test('restaura sugestão rejeitada', () {
      final history = SmartSuggestionHistory.fromJson(<String, dynamic>{
        'childId': 'child-2',
        'contentId': 'make_bed',
        'type': 'mission',
        'action': 'rejected',
        'occurredAt': '2026-09-07T12:00:00.000Z',
      });

      expect(history.type, SmartSuggestionContentType.mission);
      expect(history.action, SmartSuggestionAction.rejected);
      expect(history.contentId, 'make_bed');
    });
  });
}
