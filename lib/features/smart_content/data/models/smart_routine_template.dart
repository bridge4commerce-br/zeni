class SmartRoutineTemplate {
  const SmartRoutineTemplate({
    required this.id,
    required this.tier,
    required this.ageMin,
    required this.ageMax,
    required this.steps,
    required this.defaultPresentationSource,
    required this.orderEditable,
    required this.rewardModeSource,
    required this.autonomyValueSource,
    required this.transitionSupportSource,
    required this.priority,
    required this.culturalRelevance,
    required this.status,
    required this.title,
    required this.description,
  });

  final String id;
  final String tier;
  final int ageMin;
  final int ageMax;
  final List<String> steps;
  final String defaultPresentationSource;
  final bool orderEditable;
  final String rewardModeSource;
  final String autonomyValueSource;
  final String transitionSupportSource;
  final String priority;
  final String culturalRelevance;
  final String status;

  final String title;
  final String description;

  bool supportsAge(int age) => age >= ageMin && age <= ageMax;

  factory SmartRoutineTemplate.fromJson({
    required Map<String, dynamic> globalJson,
    required Map<String, dynamic> localizedJson,
  }) {
    final globalId = globalJson['id'] as String;
    final localizedId = localizedJson['id'] as String;

    if (globalId != localizedId) {
      throw FormatException(
        'Smart routine localization mismatch: '
        '$globalId != $localizedId',
      );
    }

    return SmartRoutineTemplate(
      id: globalId,
      tier: globalJson['tier'] as String,
      ageMin: globalJson['ageMin'] as int,
      ageMax: globalJson['ageMax'] as int,
      steps: _readStringList(globalJson['steps']),
      defaultPresentationSource:
          globalJson['defaultPresentationSource'] as String,
      orderEditable: globalJson['orderEditable'] as bool,
      rewardModeSource: globalJson['rewardModeSource'] as String,
      autonomyValueSource: globalJson['autonomyValueSource'] as String,
      transitionSupportSource: globalJson['transitionSupportSource'] as String,
      priority: globalJson['priority'] as String,
      culturalRelevance: globalJson['culturalRelevance'] as String,
      status: globalJson['status'] as String,
      title: localizedJson['title'] as String,
      description: localizedJson['description'] as String,
    );
  }
}

List<String> _readStringList(dynamic value) {
  return (value as List<dynamic>).cast<String>();
}
