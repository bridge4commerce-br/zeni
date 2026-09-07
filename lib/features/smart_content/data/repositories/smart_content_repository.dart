import '../models/smart_mission_template.dart';
import '../models/smart_routine_template.dart';

abstract class SmartContentRepository {
  Future<List<SmartMissionTemplate>> getMissions(String localeTag);

  Future<List<SmartRoutineTemplate>> getRoutines(String localeTag);
}
