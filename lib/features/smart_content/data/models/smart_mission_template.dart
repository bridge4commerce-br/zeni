class SmartMissionSupport {
  const SmartMissionSupport({
    required this.oneStepAtATime,
    required this.visual,
    required this.tts,
    required this.timer,
    required this.transition,
    required this.sensoryLoad,
    required this.cognitiveLoad,
    required this.canSplit,
  });

  final String oneStepAtATime;
  final String visual;
  final String tts;
  final String timer;
  final String transition;
  final String sensoryLoad;
  final String cognitiveLoad;
  final bool canSplit;

  factory SmartMissionSupport.fromJson(Map<String, dynamic> json) {
    return SmartMissionSupport(
      oneStepAtATime: json['oneStepAtATime'] as String,
      visual: json['visual'] as String,
      tts: json['tts'] as String,
      timer: json['timer'] as String,
      transition: json['transition'] as String,
      sensoryLoad: json['sensoryLoad'] as String,
      cognitiveLoad: json['cognitiveLoad'] as String,
      canSplit: json['canSplit'] as bool,
    );
  }
}

class SmartMissionTemplate {
  const SmartMissionTemplate({
    required this.id,
    required this.domain,
    required this.priority,
    required this.ageMin,
    required this.ageMax,
    required this.estimatedDuration,
    required this.suggestedStars,
    required this.eligibleAsExtra,
    required this.requiresApprovalByDefault,
    required this.support,
    required this.masteryPath,
    required this.culturalRelevance,
    required this.culturalTags,
    required this.status,
    required this.familyFit,
    required this.contexts,
    required this.skills,
    required this.effort,
    required this.rewardMode,
    required this.adultSupport,
    required this.safetyLevel,
    required this.applicability,
    required this.localePriority,
    required this.title,
    required this.description,
    required this.helpSteps,
  });

  final String id;
  final String domain;
  final String priority;
  final int ageMin;
  final int ageMax;
  final String estimatedDuration;
  final int suggestedStars;
  final bool eligibleAsExtra;
  final bool requiresApprovalByDefault;
  final SmartMissionSupport support;
  final String masteryPath;
  final String culturalRelevance;
  final List<String> culturalTags;
  final String status;
  final String familyFit;
  final List<String> contexts;
  final List<String> skills;
  final String effort;
  final String rewardMode;
  final String adultSupport;
  final String safetyLevel;
  final String applicability;
  final Map<String, dynamic> localePriority;

  final String title;
  final String description;
  final List<String> helpSteps;

  bool supportsAge(int age) => age >= ageMin && age <= ageMax;

  factory SmartMissionTemplate.fromJson({
    required Map<String, dynamic> globalJson,
    required Map<String, dynamic> localizedJson,
  }) {
    final globalId = globalJson['id'] as String;
    final localizedId = localizedJson['id'] as String;

    if (globalId != localizedId) {
      throw FormatException(
        'Smart mission localization mismatch: '
        '$globalId != $localizedId',
      );
    }

    return SmartMissionTemplate(
      id: globalId,
      domain: globalJson['domain'] as String,
      priority: globalJson['priority'] as String,
      ageMin: globalJson['ageMin'] as int,
      ageMax: globalJson['ageMax'] as int,
      estimatedDuration: globalJson['estimatedDuration'] as String,
      suggestedStars: globalJson['suggestedStars'] as int,
      eligibleAsExtra: globalJson['eligibleAsExtra'] as bool,
      requiresApprovalByDefault:
          globalJson['requiresApprovalByDefault'] as bool,
      support: SmartMissionSupport.fromJson(
        globalJson['support'] as Map<String, dynamic>,
      ),
      masteryPath: globalJson['masteryPath'] as String,
      culturalRelevance: globalJson['culturalRelevance'] as String,
      culturalTags: _readStringList(globalJson['culturalTags']),
      status: globalJson['status'] as String,
      familyFit: globalJson['familyFit'] as String,
      contexts: _readStringList(globalJson['contexts']),
      skills: _readStringList(globalJson['skills']),
      effort: globalJson['effort'] as String,
      rewardMode: globalJson['rewardMode'] as String,
      adultSupport: globalJson['adultSupport'] as String,
      safetyLevel: globalJson['safetyLevel'] as String,
      applicability: globalJson['applicability'] as String,
      localePriority: Map<String, dynamic>.from(
        globalJson['localePriority'] as Map<String, dynamic>,
      ),
      title: localizedJson['title'] as String,
      description: localizedJson['description'] as String,
      helpSteps: _readStringList(localizedJson['helpSteps']),
    );
  }
}

List<String> _readStringList(dynamic value) {
  return (value as List<dynamic>).cast<String>();
}
