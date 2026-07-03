import '../data/models/mission.dart';
import '../data/models/mission_log.dart';
import '../../../core/domain/zeni_enums.dart';

bool canUndoAutomaticMissionCompletion({
  required Mission mission,
  required MissionLog? log,
  DateTime? now,
}) {
  if (log == null) {
    return false;
  }

  if (log.status != MissionLogStatus.approved ||
      mission.approvalMode != MissionApprovalMode.automatic) {
    return false;
  }

  final referenceDate = now ?? DateTime.now();
  return _isSameDay(log.scheduledDate, referenceDate);
}

bool _isSameDay(DateTime value, DateTime other) {
  return value.year == other.year &&
      value.month == other.month &&
      value.day == other.day;
}
