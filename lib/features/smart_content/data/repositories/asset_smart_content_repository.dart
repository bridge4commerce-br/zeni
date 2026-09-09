import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/smart_mission_template.dart';
import '../models/smart_routine_template.dart';
import 'smart_content_repository.dart';

class AssetSmartContentRepository implements SmartContentRepository {
  AssetSmartContentRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const String fallbackLocale = 'en';

  static const List<String> supportedLocales = <String>[
    'pt-BR',
    'en',
    'es',
    'fr',
    'de',
    'ja',
  ];

  final AssetBundle _bundle;
  final Map<String, Future<Map<String, dynamic>>> _jsonCache =
      <String, Future<Map<String, dynamic>>>{};

  @override
  Future<List<SmartMissionTemplate>> getMissions(String localeTag) async {
    final globalJson = await _loadJson(
      'assets/smart_content/global/missions.json',
    );

    final locale = _resolveLocale(localeTag);
    final localizedJson = await _loadLocale(locale);
    final fallbackJson = locale == fallbackLocale
        ? localizedJson
        : await _loadLocale(fallbackLocale);

    final globalMissions = _readObjectList(globalJson, 'missions');
    final localizedById = _indexById(
      _readObjectList(localizedJson, 'missions'),
    );
    final fallbackById = _indexById(_readObjectList(fallbackJson, 'missions'));

    return globalMissions
        .map((globalMission) {
          final id = globalMission['id'] as String;
          final localizedMission = localizedById[id] ?? fallbackById[id];

          if (localizedMission == null) {
            throw FormatException(
              'Missing localization for smart mission: $id',
            );
          }

          return SmartMissionTemplate.fromJson(
            globalJson: globalMission,
            localizedJson: localizedMission,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<SmartRoutineTemplate>> getRoutines(String localeTag) async {
    final globalJson = await _loadJson(
      'assets/smart_content/global/routines.json',
    );

    final locale = _resolveLocale(localeTag);
    final localizedJson = await _loadLocale(locale);
    final fallbackJson = locale == fallbackLocale
        ? localizedJson
        : await _loadLocale(fallbackLocale);

    final globalRoutines = _readObjectList(globalJson, 'routines');
    final localizedById = _indexById(
      _readObjectList(localizedJson, 'routines'),
    );
    final fallbackById = _indexById(_readObjectList(fallbackJson, 'routines'));

    final routines = globalRoutines
        .map((globalRoutine) {
          final id = globalRoutine['id'] as String;
          final localizedRoutine = localizedById[id] ?? fallbackById[id];

          if (localizedRoutine == null) {
            throw FormatException(
              'Missing localization for smart routine: $id',
            );
          }

          return SmartRoutineTemplate.fromJson(
            globalJson: globalRoutine,
            localizedJson: localizedRoutine,
          );
        })
        .toList(growable: false);
    final missions = await getMissions(localeTag);
    final missionIds = missions.map((mission) => mission.id).toSet();
    for (final routine in routines) {
      for (final missionId in routine.steps) {
        if (!missionIds.contains(missionId)) {
          throw FormatException(
            'Routine ${routine.id} references missing mission $missionId',
          );
        }
      }
    }
    return routines;
  }

  Future<Map<String, dynamic>> _loadLocale(String locale) {
    return _loadJson('assets/smart_content/locales/$locale.json');
  }

  Future<Map<String, dynamic>> _loadJson(String path) {
    return _jsonCache.putIfAbsent(path, () async {
      final raw = await _bundle.loadString(path);
      final decoded = jsonDecode(raw);

      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Invalid smart content JSON: $path');
      }

      return decoded;
    });
  }

  String _resolveLocale(String localeTag) {
    final normalized = localeTag.trim().replaceAll('_', '-');

    for (final locale in supportedLocales) {
      if (locale.toLowerCase() == normalized.toLowerCase()) {
        return locale;
      }
    }

    final languageCode = normalized.split('-').first.toLowerCase();

    if (languageCode == 'pt') return 'pt-BR';

    for (final locale in supportedLocales) {
      if (locale.toLowerCase() == languageCode) {
        return locale;
      }
    }

    return fallbackLocale;
  }

  List<Map<String, dynamic>> _readObjectList(
    Map<String, dynamic> json,
    String key,
  ) {
    final rawList = json[key];

    if (rawList is! List<dynamic>) {
      throw FormatException('Missing or invalid smart content list: $key');
    }

    return rawList
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw FormatException('Invalid smart content item in: $key');
          }

          return item;
        })
        .toList(growable: false);
  }

  Map<String, Map<String, dynamic>> _indexById(
    List<Map<String, dynamic>> items,
  ) {
    final result = <String, Map<String, dynamic>>{};

    for (final item in items) {
      final id = item['id'];

      if (id is! String || id.isEmpty) {
        throw const FormatException('Smart content item without valid id');
      }

      if (result.containsKey(id)) {
        throw FormatException('Duplicate smart content id: $id');
      }

      result[id] = item;
    }

    return result;
  }
}
