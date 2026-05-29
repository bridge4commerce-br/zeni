import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';

void main() {
  Mission buildMission({
    required MissionRecurrence recurrence,
    DateTime? createdAt,
    List<int> customDaysOfWeek = const <int>[],
  }) {
    final date = createdAt ?? DateTime(2026, 5, 15);

    return Mission(
      id: 'mission-1',
      familyId: 'family-1',
      childId: 'child-1',
      title: 'Missao teste',
      description: 'Descricao',
      stars: 10,
      recurrence: recurrence,
      customDaysOfWeek: customDaysOfWeek,
      timeGroup: MissionTimeGroup.morning,
      approvalMode: MissionApprovalMode.automatic,
      status: MissionStatus.active,
      createdAt: date,
      updatedAt: date,
    );
  }

  group('Mission recurrence', () {
    test('once occurs only on the created date', () {
      final mission = buildMission(
        recurrence: MissionRecurrence.once,
        createdAt: DateTime(2026, 5, 15),
      );

      expect(mission.occursOnDate(DateTime(2026, 5, 15)), isTrue);
      expect(mission.occursOnDate(DateTime(2026, 5, 14)), isFalse);
      expect(mission.occursOnDate(DateTime(2026, 5, 16)), isFalse);
      expect(mission.remainingOccurrencesInMonth(DateTime(2026, 5, 1)), 1);
      expect(mission.remainingOccurrencesInMonth(DateTime(2026, 5, 16)), 0);
    });

    test('daily occurs every day from the created date onward', () {
      final mission = buildMission(
        recurrence: MissionRecurrence.daily,
        createdAt: DateTime(2026, 5, 28),
      );

      expect(mission.occursOnDate(DateTime(2026, 5, 27)), isFalse);
      expect(mission.occursOnDate(DateTime(2026, 5, 28)), isTrue);
      expect(mission.occursOnDate(DateTime(2026, 5, 31)), isTrue);
      expect(mission.remainingOccurrencesInMonth(DateTime(2026, 5, 29)), 3);
    });

    test('weekdays occurs only on business days', () {
      final mission = buildMission(
        recurrence: MissionRecurrence.weekdays,
        createdAt: DateTime(2026, 5, 1),
      );

      expect(mission.occursOnDate(DateTime(2026, 5, 29)), isTrue);
      expect(mission.occursOnDate(DateTime(2026, 5, 30)), isFalse);
      expect(mission.occursOnDate(DateTime(2026, 5, 31)), isFalse);
      expect(mission.remainingOccurrencesInMonth(DateTime(2026, 5, 27)), 3);
    });

    test('weekends occurs only on saturday and sunday', () {
      final mission = buildMission(
        recurrence: MissionRecurrence.weekends,
        createdAt: DateTime(2026, 5, 1),
      );

      expect(mission.occursOnDate(DateTime(2026, 5, 29)), isFalse);
      expect(mission.occursOnDate(DateTime(2026, 5, 30)), isTrue);
      expect(mission.occursOnDate(DateTime(2026, 5, 31)), isTrue);
      expect(mission.remainingOccurrencesInMonth(DateTime(2026, 5, 27)), 2);
    });

    test('customDaysOfWeek uses the configured weekdays', () {
      final mission = buildMission(
        recurrence: MissionRecurrence.customDaysOfWeek,
        createdAt: DateTime(2026, 5, 1),
        customDaysOfWeek: const [DateTime.monday, DateTime.wednesday],
      );

      expect(mission.occursOnDate(DateTime(2026, 5, 27)), isTrue);
      expect(mission.occursOnDate(DateTime(2026, 5, 28)), isFalse);
      expect(mission.occursOnDate(DateTime(2026, 5, 29)), isFalse);
      expect(mission.remainingOccurrencesInMonth(DateTime(2026, 5, 27)), 1);
    });

    test('customDaysOfWeek sanitizes duplicates and invalid values', () {
      final mission = buildMission(
        recurrence: MissionRecurrence.customDaysOfWeek,
        customDaysOfWeek: const [0, 1, 1, 3, 9],
      );

      expect(mission.effectiveCustomDaysOfWeek, const [1, 3]);
    });

    test(
      'old custom recurrence falls back safely when no days were persisted',
      () {
        final mission = Mission.fromJson({
          'id': 'mission-1',
          'familyId': 'family-1',
          'childId': 'child-1',
          'title': 'Missao antiga',
          'description': 'Descricao',
          'emoji': '✅',
          'stars': 10,
          'recurrence': 'custom',
          'timeGroup': 'morning',
          'approvalMode': 'automatic',
          'status': 'active',
          'requiresPhoto': false,
          'createdAt': DateTime(2026, 5, 1).toIso8601String(),
          'updatedAt': DateTime(2026, 5, 1).toIso8601String(),
        });

        expect(mission.recurrence, MissionRecurrence.customDaysOfWeek);
        expect(
          mission.effectiveCustomDaysOfWeek,
          Mission.fallbackCustomDaysOfWeek,
        );
        expect(mission.occursOnDate(DateTime(2026, 5, 30)), isTrue);
      },
    );

    test('invalid stored recurrence falls back to daily', () {
      final mission = Mission.fromJson({
        'id': 'mission-1',
        'familyId': 'family-1',
        'childId': 'child-1',
        'title': 'Missao antiga',
        'description': 'Descricao',
        'emoji': '✅',
        'stars': 10,
        'recurrence': 'unexpected-value',
        'timeGroup': 'morning',
        'approvalMode': 'automatic',
        'status': 'active',
        'requiresPhoto': false,
        'createdAt': DateTime(2026, 5, 1).toIso8601String(),
        'updatedAt': DateTime(2026, 5, 1).toIso8601String(),
      });

      expect(mission.recurrence, MissionRecurrence.daily);
      expect(mission.occursOnDate(DateTime(2026, 5, 2)), isTrue);
    });

    test('serialization keeps customDaysOfWeek', () {
      final mission = buildMission(
        recurrence: MissionRecurrence.customDaysOfWeek,
        customDaysOfWeek: const [DateTime.tuesday, DateTime.thursday],
      );

      final decoded = Mission.fromJson(mission.toJson());

      expect(decoded.recurrence, MissionRecurrence.customDaysOfWeek);
      expect(decoded.effectiveCustomDaysOfWeek, const [
        DateTime.tuesday,
        DateTime.thursday,
      ]);
    });
  });
}
