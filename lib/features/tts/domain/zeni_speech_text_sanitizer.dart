class ZeniSpeechTextSanitizer {
  const ZeniSpeechTextSanitizer._();

  static final List<RegExp> _technicalPatterns = <RegExp>[
    RegExp(r'\brestaurad[ao]s?\b'),
    RegExp(r'\bnuvem\b'),
    RegExp(r'\bsync\b'),
    RegExp(r'\bsincronizad[ao]s?\b'),
    RegExp(r'\blocal\b'),
    RegExp(r'\bremot[oa]s?\b'),
    RegExp(r'\bledger\b'),
    RegExp(r'\bsupabase\b'),
    RegExp(r'\bpending\b'),
    RegExp(r'\bawaitingapproval\b'),
    RegExp(r'\bapproved\b'),
    RegExp(r'\brejected\b'),
    RegExp(r'\bparentapproval\b'),
    RegExp(r'\bautomatic\b'),
    RegExp(r'\bid\b'),
    RegExp(
      r'\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b',
    ),
  ];

  static bool isTechnicalSpeechText(String text) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) return false;

    for (final pattern in _technicalPatterns) {
      if (pattern.hasMatch(normalized)) {
        return true;
      }
    }

    return false;
  }

  static String? sanitizeMissionDescriptionForSpeech(String? description) {
    return _sanitizeDescription(description);
  }

  static String? sanitizeRewardDescriptionForSpeech(String? description) {
    return _sanitizeDescription(description);
  }

  static String? _sanitizeDescription(String? description) {
    final trimmed = description?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    if (isTechnicalSpeechText(trimmed)) {
      return null;
    }

    return trimmed;
  }

  static String _normalize(String value) {
    final lower = value.toLowerCase().trim();
    if (lower.isEmpty) {
      return '';
    }

    return lower
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }
}
