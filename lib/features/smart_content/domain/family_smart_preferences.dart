class FamilySmartPreferences {
  const FamilySmartPreferences({
    this.enabledDomains = const <String>{
      'self_care',
      'belongings',
      'meals',
      'study',
      'home_participation',
      'transitions',
      'life_skills',
    },
    this.supervisionAvailable = true,
  });

  final Set<String> enabledDomains;
  final bool supervisionAvailable;

  bool isDomainEnabled(String domain) => enabledDomains.contains(domain);
}
