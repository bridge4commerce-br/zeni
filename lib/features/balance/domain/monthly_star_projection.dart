import '../../family/data/models/child_profile.dart';
import '../../tasks/data/models/mission.dart';
import '../../../core/domain/zeni_enums.dart';

enum MonthlyProjectionScenario { conservative, realistic, maximum }

extension MonthlyProjectionScenarioX on MonthlyProjectionScenario {
  String get label {
    return switch (this) {
      MonthlyProjectionScenario.conservative => 'Conservador',
      MonthlyProjectionScenario.realistic => 'Realista',
      MonthlyProjectionScenario.maximum => 'Máximo',
    };
  }
}

class MonthlyProjectionScenarioResult {
  const MonthlyProjectionScenarioResult({
    required this.scenario,
    required this.projectedEarnedStars,
    required this.projectedBalance,
  });

  final MonthlyProjectionScenario scenario;
  final int projectedEarnedStars;
  final int projectedBalance;
}

class MonthlyStarProjectionResult {
  const MonthlyStarProjectionResult({
    required this.currentBalance,
    required this.daysRemainingInMonth,
    required this.maxPossibleStars,
    required this.totalRemainingOccurrences,
    required this.scenarios,
  });

  final int currentBalance;
  final int daysRemainingInMonth;
  final int maxPossibleStars;
  final int totalRemainingOccurrences;
  final List<MonthlyProjectionScenarioResult> scenarios;

  MonthlyProjectionScenarioResult scenario(MonthlyProjectionScenario scenario) {
    return scenarios.firstWhere((item) => item.scenario == scenario);
  }
}

class MonthlyStarProjectionCalculator {
  const MonthlyStarProjectionCalculator();

  static const Map<MonthlyProjectionScenario, double> _automaticRates = {
    MonthlyProjectionScenario.conservative: 0.45,
    MonthlyProjectionScenario.realistic: 0.75,
    MonthlyProjectionScenario.maximum: 1.0,
  };

  static const Map<MonthlyProjectionScenario, double> _approvalRates = {
    MonthlyProjectionScenario.conservative: 0.30,
    MonthlyProjectionScenario.realistic: 0.60,
    MonthlyProjectionScenario.maximum: 1.0,
  };

  MonthlyStarProjectionResult calculateForChild({
    required ChildProfile child,
    required List<Mission> activeMissions,
    DateTime? now,
  }) {
    final referenceDate = _dateOnly(now ?? DateTime.now());
    final monthEnd = DateTime(referenceDate.year, referenceDate.month + 1, 0);
    final daysRemainingInMonth = monthEnd.difference(referenceDate).inDays + 1;

    final childMissions = activeMissions
        .where((mission) => mission.isActive && mission.childId == child.id)
        .toList();

    final occurrenceBreakdowns = childMissions
        .map(
          (mission) => _MissionProjectionBreakdown(
            mission: mission,
            remainingOccurrences: mission.remainingOccurrencesInMonth(
              referenceDate,
            ),
          ),
        )
        .where((breakdown) => breakdown.remainingOccurrences > 0)
        .toList();

    final maxPossibleStars = occurrenceBreakdowns.fold<int>(
      0,
      (total, breakdown) =>
          total + (breakdown.remainingOccurrences * breakdown.mission.stars),
    );

    final totalRemainingOccurrences = occurrenceBreakdowns.fold<int>(
      0,
      (total, breakdown) => total + breakdown.remainingOccurrences,
    );

    final scenarios = MonthlyProjectionScenario.values.map((scenario) {
      final projectedEarnedStars = occurrenceBreakdowns
          .map((breakdown) => _projectMissionStars(breakdown, scenario))
          .fold<int>(0, (total, stars) => total + stars);

      return MonthlyProjectionScenarioResult(
        scenario: scenario,
        projectedEarnedStars: projectedEarnedStars,
        projectedBalance: child.starBalance + projectedEarnedStars,
      );
    }).toList();

    return MonthlyStarProjectionResult(
      currentBalance: child.starBalance,
      daysRemainingInMonth: daysRemainingInMonth,
      maxPossibleStars: maxPossibleStars,
      totalRemainingOccurrences: totalRemainingOccurrences,
      scenarios: scenarios,
    );
  }

  int _projectMissionStars(
    _MissionProjectionBreakdown breakdown,
    MonthlyProjectionScenario scenario,
  ) {
    final rate =
        breakdown.mission.approvalMode == MissionApprovalMode.parentApproval
        ? _approvalRates[scenario]!
        : _automaticRates[scenario]!;

    final rawStars =
        breakdown.remainingOccurrences * breakdown.mission.stars * rate;
    return rawStars.round();
  }
}

class _MissionProjectionBreakdown {
  const _MissionProjectionBreakdown({
    required this.mission,
    required this.remainingOccurrences,
  });

  final Mission mission;
  final int remainingOccurrences;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
