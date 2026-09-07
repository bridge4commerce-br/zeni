import '../../family/data/models/child_profile.dart';
import '../../tasks/data/models/mission.dart';
import '../data/models/smart_mission_template.dart';
import '../data/models/smart_suggestion.dart';
import '../data/models/smart_suggestion_history.dart';
import '../data/repositories/smart_content_repository.dart';
import 'family_smart_preferences.dart';
import 'smart_suggestion_context_profile.dart';
import 'smart_suggestion_enums.dart';
import 'smart_suggestion_goal_profile.dart';

class SmartSuggestionService {
  const SmartSuggestionService(this._repository);

  final SmartContentRepository _repository;

  Future<List<SmartSuggestion>> suggest({
    required ChildProfile child,
    required SmartSuggestionGoal goal,
    SmartSuggestionContext context = SmartSuggestionContext.none,
    required FamilySmartPreferences preferences,
    required List<Mission> activeMissions,
    required List<SmartSuggestionHistory> history,
    String localeTag = 'pt-BR',
    DateTime? now,
    int limit = 5,
  }) async {
    if (limit <= 0) {
      return const <SmartSuggestion>[];
    }

    final referenceDate = now ?? DateTime.now();
    final age = _ageOnDate(child.birthDate, referenceDate);
    final missions = await _repository.getMissions(localeTag);

    final activeTitles = activeMissions
        .where((mission) => mission.childId == child.id && mission.isActive)
        .map((mission) => _normalize(mission.title))
        .toSet();

    final ranked = <SmartMissionSuggestion>[];

    for (final mission in missions) {
      if (!preferences.isDomainEnabled(mission.domain)) {
        continue;
      }

      if (age != null && !mission.supportsAge(age)) {
        continue;
      }

      if (activeTitles.contains(_normalize(mission.title))) {
        continue;
      }

      if (!_isContextApplicable(mission, context)) {
        continue;
      }

      if (!preferences.supervisionAvailable &&
          _requiresSupervision(mission.adultSupport)) {
        continue;
      }

      final score = _scoreMission(
        mission: mission,
        childId: child.id,
        age: age,
        goal: goal,
        context: context,
        history: history,
        now: referenceDate,
      );

      ranked.add(SmartMissionSuggestion(mission: mission, score: score));
    }

    ranked.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) {
        return scoreComparison;
      }

      return a.contentId.compareTo(b.contentId);
    });

    return ranked.take(limit.clamp(1, 5)).toList(growable: false);
  }

  int _scoreMission({
    required SmartMissionTemplate mission,
    required String childId,
    required int? age,
    required SmartSuggestionGoal goal,
    required SmartSuggestionContext context,
    required List<SmartSuggestionHistory> history,
    required DateTime now,
  }) {
    var score = 0;

    final profile = goal.profile;

    if (profile.preferredDomains.contains(mission.domain)) {
      score += 30;
    }

    if (context != SmartSuggestionContext.none &&
        mission.contexts.any(context.contentTags.contains)) {
      score += 25;
    }

    if (mission.skills.any(profile.targetSkills.contains)) {
      score += 20;
    }

    if (age != null && _isGoodAgeFit(mission, age)) {
      score += 10;
    }

    final recentHistory = history.where(
      (item) =>
          item.childId == childId &&
          item.contentId == mission.id &&
          now.difference(item.occurredAt).inDays.abs() <= 30,
    );

    if (recentHistory.isEmpty) {
      score += 10;
    }

    if (recentHistory.any(
      (item) => item.action == SmartSuggestionAction.rejected,
    )) {
      score -= 30;
    }

    return score;
  }

  bool _isContextApplicable(
    SmartMissionTemplate mission,
    SmartSuggestionContext context,
  ) {
    if (context == SmartSuggestionContext.none) {
      return true;
    }

    if (mission.contexts.contains('family_defined') ||
        mission.contexts.contains('planning')) {
      return true;
    }

    return mission.contexts.any(context.contentTags.contains);
  }

  bool _requiresSupervision(String adultSupport) {
    final value = adultSupport.toLowerCase();

    return value.contains('supervision') ||
        value.contains('adult_required') ||
        value.contains('required_adult');
  }

  bool _isGoodAgeFit(SmartMissionTemplate mission, int age) {
    final middle = (mission.ageMin + mission.ageMax) / 2;
    final radius = (mission.ageMax - mission.ageMin) / 4;

    return (age - middle).abs() <= radius.clamp(1, double.infinity);
  }

  int? _ageOnDate(DateTime? birthDate, DateTime date) {
    if (birthDate == null || birthDate.isAfter(date)) {
      return null;
    }

    var age = date.year - birthDate.year;

    final birthdayHasOccurred =
        date.month > birthDate.month ||
        (date.month == birthDate.month && date.day >= birthDate.day);

    if (!birthdayHasOccurred) {
      age -= 1;
    }

    return age;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}
