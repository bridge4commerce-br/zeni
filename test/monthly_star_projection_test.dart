import 'package:flutter_test/flutter_test.dart';
import 'package:zeni/core/domain/zeni_enums.dart';
import 'package:zeni/features/balance/domain/monthly_star_projection.dart';
import 'package:zeni/features/family/data/models/child_profile.dart';
import 'package:zeni/features/tasks/data/models/mission.dart';

void main() {
  ChildProfile buildChild({int starBalance = 120}) {
    return ChildProfile(
      id: 'child-1',
      familyId: 'family-1',
      name: 'Luna',
      emoji: '🦊',
      starBalance: starBalance,
      streakCount: 0,
      createdAt: DateTime(2026, 5, 1),
    );
  }

  Mission buildMission({
    required String id,
    required int stars,
    required MissionRecurrence recurrence,
    MissionApprovalMode approvalMode = MissionApprovalMode.automatic,
    List<int> customDaysOfWeek = const <int>[],
  }) {
    return Mission(
      id: id,
      familyId: 'family-1',
      childId: 'child-1',
      title: 'Missão $id',
      description: 'Descrição',
      stars: stars,
      recurrence: recurrence,
      customDaysOfWeek: customDaysOfWeek,
      timeGroup: MissionTimeGroup.morning,
      approvalMode: approvalMode,
      status: MissionStatus.active,
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );
  }

  test('calculates monthly projection scenarios using active missions', () {
    const calculator = MonthlyStarProjectionCalculator();
    final child = buildChild(starBalance: 100);
    final now = DateTime(2026, 5, 27);

    final missions = [
      buildMission(
        id: 'daily-auto',
        stars: 10,
        recurrence: MissionRecurrence.daily,
      ),
      buildMission(
        id: 'weekdays-approval',
        stars: 20,
        recurrence: MissionRecurrence.weekdays,
        approvalMode: MissionApprovalMode.parentApproval,
      ),
      buildMission(
        id: 'once-auto',
        stars: 15,
        recurrence: MissionRecurrence.once,
      ),
    ];

    final result = calculator.calculateForChild(
      child: child,
      activeMissions: missions,
      now: now,
    );

    expect(result.currentBalance, 100);
    expect(result.daysRemainingInMonth, 5);
    expect(result.totalRemainingOccurrences, 8);
    expect(result.maxPossibleStars, 110);

    expect(
      result
          .scenario(MonthlyProjectionScenario.conservative)
          .projectedEarnedStars,
      41,
    );
    expect(
      result.scenario(MonthlyProjectionScenario.realistic).projectedEarnedStars,
      74,
    );
    expect(
      result.scenario(MonthlyProjectionScenario.maximum).projectedEarnedStars,
      110,
    );

    expect(
      result.scenario(MonthlyProjectionScenario.conservative).projectedBalance,
      141,
    );
    expect(
      result.scenario(MonthlyProjectionScenario.realistic).projectedBalance,
      174,
    );
    expect(
      result.scenario(MonthlyProjectionScenario.maximum).projectedBalance,
      210,
    );
  });

  test('ignores archived and other child missions', () {
    const calculator = MonthlyStarProjectionCalculator();
    final child = buildChild();
    final now = DateTime(2026, 5, 27);

    final ownMission = buildMission(
      id: 'daily-auto',
      stars: 10,
      recurrence: MissionRecurrence.daily,
    );
    final otherChildMission = ownMission.copyWith(
      id: 'other-child',
      childId: 'child-2',
    );
    final archivedMission = ownMission.copyWith(
      id: 'archived',
      status: MissionStatus.archived,
    );

    final result = calculator.calculateForChild(
      child: child,
      activeMissions: [ownMission, otherChildMission, archivedMission],
      now: now,
    );

    expect(result.maxPossibleStars, 50);
    expect(result.totalRemainingOccurrences, 5);
  });

  test('custom days recurrence contributes only matching remaining days', () {
    const calculator = MonthlyStarProjectionCalculator();
    final child = buildChild(starBalance: 50);
    final now = DateTime(2026, 5, 27);

    final missions = [
      buildMission(
        id: 'custom',
        stars: 12,
        recurrence: MissionRecurrence.customDaysOfWeek,
        customDaysOfWeek: const [DateTime.wednesday, DateTime.saturday],
      ),
    ];

    final result = calculator.calculateForChild(
      child: child,
      activeMissions: missions,
      now: now,
    );

    expect(result.totalRemainingOccurrences, 2);
    expect(result.maxPossibleStars, 24);
    expect(
      result.scenario(MonthlyProjectionScenario.maximum).projectedBalance,
      74,
    );
  });
}
