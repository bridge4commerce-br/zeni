import 'smart_suggestion_enums.dart';

class SmartSuggestionGoalProfile {
  const SmartSuggestionGoalProfile({
    required this.preferredDomains,
    required this.targetSkills,
  });

  final Set<String> preferredDomains;
  final Set<String> targetSkills;
}

extension SmartSuggestionGoalProfileX on SmartSuggestionGoal {
  SmartSuggestionGoalProfile get profile {
    return switch (this) {
      SmartSuggestionGoal.autonomy => const SmartSuggestionGoalProfile(
        preferredDomains: <String>{'self_care', 'meals'},
        targetSkills: <String>{'autonomy', 'self_care', 'independence'},
      ),
      SmartSuggestionGoal.organization => const SmartSuggestionGoalProfile(
        preferredDomains: <String>{'belongings', 'transitions'},
        targetSkills: <String>{
          'organization',
          'planning_working_memory',
          'planning_organization',
        },
      ),
      SmartSuggestionGoal.study => const SmartSuggestionGoalProfile(
        preferredDomains: <String>{'study'},
        targetSkills: <String>{'task_initiation_focus', 'planning_review'},
      ),
      SmartSuggestionGoal.routine => const SmartSuggestionGoalProfile(
        preferredDomains: <String>{'transitions', 'self_care', 'meals'},
        targetSkills: <String>{
          'transitions',
          'routine_participation',
          'sequence_working_memory',
        },
      ),
      SmartSuggestionGoal.homeParticipation => const SmartSuggestionGoalProfile(
        preferredDomains: <String>{'home_participation'},
        targetSkills: <String>{'family_participation', 'responsibility'},
      ),
      SmartSuggestionGoal.lifeSkills => const SmartSuggestionGoalProfile(
        preferredDomains: <String>{'life_skills'},
        targetSkills: <String>{'independence', 'planning', 'autonomy'},
      ),
      SmartSuggestionGoal.digital => const SmartSuggestionGoalProfile(
        preferredDomains: <String>{'digital'},
        targetSkills: <String>{
          'digital_responsibility',
          'planning_organization',
        },
      ),
    };
  }
}
