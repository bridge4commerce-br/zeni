import 'smart_mission_template.dart';
import 'smart_routine_template.dart';

sealed class SmartSuggestion {
  const SmartSuggestion({required this.score});

  final int score;

  String get contentId;
}

final class SmartMissionSuggestion extends SmartSuggestion {
  const SmartMissionSuggestion({required this.mission, required super.score});

  final SmartMissionTemplate mission;

  @override
  String get contentId => mission.id;
}

final class SmartRoutineSuggestion extends SmartSuggestion {
  const SmartRoutineSuggestion({required this.routine, required super.score});

  final SmartRoutineTemplate routine;

  @override
  String get contentId => routine.id;
}
