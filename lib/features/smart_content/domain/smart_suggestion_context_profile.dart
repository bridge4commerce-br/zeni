import 'smart_suggestion_enums.dart';

extension SmartSuggestionContextProfileX on SmartSuggestionContext {
  Set<String> get contentTags {
    return switch (this) {
      SmartSuggestionContext.morning => <String>{'morning', 'planning'},
      SmartSuggestionContext.beforeSchool => <String>{
        'school_prep',
        'school',
        'morning',
      },
      SmartSuggestionContext.afterSchool => <String>{'after_school', 'arrival'},
      SmartSuggestionContext.homework => <String>{
        'study',
        'school',
        'planning',
      },
      SmartSuggestionContext.beforeMeal => <String>{'meal'},
      SmartSuggestionContext.afterMeal => <String>{'after_meal', 'meal'},
      SmartSuggestionContext.beforeLeaving => <String>{
        'before_leaving',
        'planning',
      },
      SmartSuggestionContext.arrival => <String>{
        'arrival',
        'after_school',
        'after_trip',
      },
      SmartSuggestionContext.bedtime => <String>{
        'noite_antes_de_dormir',
        'planning',
      },
      SmartSuggestionContext.weekend => <String>{
        'weekly',
        'planning',
        'family_defined',
      },
      SmartSuggestionContext.none => <String>{},
    };
  }
}
