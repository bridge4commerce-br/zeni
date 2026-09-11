enum ZeniTtsPlatformKind { android, apple, other }

class ZeniTtsVoice {
  const ZeniTtsVoice({
    this.name,
    this.locale,
    this.identifier,
    this.quality,
    this.networkRequired,
  });

  final String? name;
  final String? locale;
  final String? identifier;
  final int? quality;
  final bool? networkRequired;

  bool get isSelectable =>
      name?.trim().isNotEmpty == true && locale?.trim().isNotEmpty == true;
}

class ZeniTtsLocale {
  const ZeniTtsLocale._();

  static String normalize(String locale) {
    final segments = locale
        .trim()
        .replaceAll('_', '-')
        .split('-')
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.isEmpty) return '';

    return segments
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final segment = entry.value;
          if (index == 0) return segment.toLowerCase();
          if (segment.length == 4) {
            return '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}';
          }
          if (segment.length == 2 || segment.length == 3) {
            return segment.toUpperCase();
          }
          return segment.toLowerCase();
        })
        .join('-');
  }

  static String languageCode(String locale) {
    final normalized = normalize(locale);
    if (normalized.isEmpty) {
      return '';
    }
    return normalized.split('-').first;
  }
}

class ZeniTtsVoiceSelector {
  const ZeniTtsVoiceSelector._();

  static ZeniTtsVoice? select({
    required Iterable<ZeniTtsVoice> voices,
    required String requestedLocale,
    required ZeniTtsPlatformKind platform,
  }) {
    final locale = ZeniTtsLocale.normalize(requestedLocale);
    if (locale.isEmpty) return null;

    final candidates = voices.where((voice) => voice.isSelectable).toList();
    if (candidates.isEmpty) return null;

    candidates.sort((first, second) {
      final firstRank = _rank(first, locale, platform);
      final secondRank = _rank(second, locale, platform);
      for (var index = 0; index < firstRank.length; index++) {
        final comparison = firstRank[index].compareTo(secondRank[index]);
        if (comparison != 0) return comparison;
      }
      return _stableIdentifier(first).compareTo(_stableIdentifier(second));
    });

    final selected = candidates.first;
    return _localeMatch(selected, locale) == _LocaleMatch.none
        ? null
        : selected;
  }

  static List<int> _rank(
    ZeniTtsVoice voice,
    String locale,
    ZeniTtsPlatformKind platform,
  ) {
    final localeMatch = _localeMatch(voice, locale);
    final quality = voice.quality ?? 0;

    if (platform == ZeniTtsPlatformKind.android) {
      return <int>[
        _androidConnectivityRank(voice.networkRequired),
        _localeRank(localeMatch),
        -quality,
      ];
    }

    return <int>[_localeRank(localeMatch), -quality];
  }

  static int _androidConnectivityRank(bool? networkRequired) {
    if (networkRequired == false) return 0;
    if (networkRequired == null) return 1;
    return 2;
  }

  static int _localeRank(_LocaleMatch match) {
    return switch (match) {
      _LocaleMatch.exact => 0,
      _LocaleMatch.language => 1,
      _LocaleMatch.none => 2,
    };
  }

  static _LocaleMatch _localeMatch(ZeniTtsVoice voice, String locale) {
    final voiceLocale = ZeniTtsLocale.normalize(voice.locale ?? '');
    if (voiceLocale.isEmpty) return _LocaleMatch.none;
    if (voiceLocale == locale) return _LocaleMatch.exact;
    return ZeniTtsLocale.languageCode(voiceLocale) ==
            ZeniTtsLocale.languageCode(locale)
        ? _LocaleMatch.language
        : _LocaleMatch.none;
  }

  static String _stableIdentifier(ZeniTtsVoice voice) =>
      '${voice.identifier ?? ''}\u0000${voice.name ?? ''}\u0000${voice.locale ?? ''}'
          .toLowerCase();
}

enum _LocaleMatch { exact, language, none }
