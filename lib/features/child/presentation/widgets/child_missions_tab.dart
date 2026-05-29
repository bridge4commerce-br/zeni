import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/models/mission_log.dart';
import '../../../tasks/presentation/widgets/task_child_detail_sheet.dart';
import '../../../tasks/presentation/widgets/task_compact_child_card.dart';
import '../../../tasks/presentation/widgets/task_time_group_header.dart';

class ChildMissionsTab extends StatelessWidget {
  const ChildMissionsTab({
    super.key,
    required this.missions,
    required this.logForMission,
    required this.missionAnchorKeyFor,
    required this.onCompleteMission,
    required this.onCancelMissionSubmission,
  });

  final List<Mission> missions;
  final MissionLog? Function(String missionId) logForMission;
  final GlobalKey Function(String missionId) missionAnchorKeyFor;
  final void Function(Mission mission, MissionLog? log, GlobalKey? sourceKey)
  onCompleteMission;
  final void Function(Mission mission, MissionLog? log)
  onCancelMissionSubmission;

  @override
  Widget build(BuildContext context) {
    final groups = MissionTimeGroup.values
        .where((group) => missions.any((mission) => mission.timeGroup == group))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ZeniSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Minhas missões',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            'Toque em uma missão para ver detalhes.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.xl),
          for (final group in groups) ...[
            TaskTimeGroupHeader(group: group),
            const SizedBox(height: ZeniSpacing.md),
            for (final mission in missions.where(
              (mission) => mission.timeGroup == group,
            )) ...[
              KeyedSubtree(
                key: missionAnchorKeyFor('missions:${mission.id}'),
                child: TaskCompactChildCard(
                  mission: mission,
                  log: logForMission(mission.id),
                  onTap: () async {
                    final log = logForMission(mission.id);

                    final action =
                        await showModalBottomSheet<TaskChildDetailAction>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (context) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.viewInsetsOf(context).bottom,
                              ),
                              child: TaskChildDetailSheet(
                                mission: mission,
                                log: log,
                              ),
                            );
                          },
                        );

                    if (!context.mounted) return;

                    switch (action) {
                      case TaskChildDetailAction.complete:
                        onCompleteMission(
                          mission,
                          logForMission(mission.id),
                          missionAnchorKeyFor('missions:${mission.id}'),
                        );
                      case TaskChildDetailAction.cancelSubmission:
                        onCancelMissionSubmission(
                          mission,
                          logForMission(mission.id),
                        );
                      case null:
                        break;
                    }
                  },
                ),
              ),
              const SizedBox(height: ZeniSpacing.sm),
            ],
            const SizedBox(height: ZeniSpacing.lg),
          ],
        ],
      ),
    );
  }
}
