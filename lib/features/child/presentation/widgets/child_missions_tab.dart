import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/widgets/base/zeni_surface.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/models/mission_log.dart';
import '../../../tasks/domain/mission_undo_policy.dart';
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
    required this.onUndoMissionCompletion,
    required this.onListenToMissionDetails,
    required this.onStopMissionSpeech,
    required this.canListenToMission,
    this.onRefresh,
  });

  final List<Mission> missions;
  final MissionLog? Function(String missionId) logForMission;
  final GlobalKey Function(String missionId) missionAnchorKeyFor;
  final void Function(
    Mission mission,
    MissionLog? log,
    GlobalKey? sourceKey, {
    String? note,
  })
  onCompleteMission;
  final void Function(Mission mission, MissionLog? log)
  onCancelMissionSubmission;
  final void Function(Mission mission, MissionLog? log)
  onListenToMissionDetails;
  final Future<void> Function() onStopMissionSpeech;
  final void Function(Mission mission, MissionLog log) onUndoMissionCompletion;
  final bool canListenToMission;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final groups = MissionTimeGroup.values
        .where((group) => missions.any((mission) => mission.timeGroup == group))
        .toList();

    final content = SingleChildScrollView(
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: ZeniSpacing.spaceSection,
        bottom: ZeniSpacing.spaceCanvas + MediaQuery.paddingOf(context).bottom,
      ),
      child: ZeniPageFrame(
        width: ZeniPageWidth.main,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Minhas missões', style: ZeniTypography.of(context).pageTitle),
            const SizedBox(height: ZeniSpacing.spaceInline),
            Text(
              'Toque em uma missão para ver detalhes.',
              style: ZeniTypography.of(context).body,
            ),
            const SizedBox(height: ZeniSpacing.spaceSection),
            for (final group in groups) ...[
              TaskTimeGroupHeader(group: group),
              const SizedBox(height: ZeniSpacing.spaceCard),
              ZeniSurface(
                role: ZeniSurfaceRole.grouped,
                mode: ZeniVisualMode.kids,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
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

                            final result = await showTaskChildDetailModal(
                              context: context,
                              mission: mission,
                              onListenToMissionDetails: () =>
                                  onListenToMissionDetails(
                                    mission,
                                    logForMission(mission.id),
                                  ),
                              onDismiss: onStopMissionSpeech,
                              log: log,
                              showListenActions: canListenToMission,
                              canUndoCompletion:
                                  canUndoAutomaticMissionCompletion(
                                    mission: mission,
                                    log: log,
                                  ),
                            );

                            if (!context.mounted) return;

                            switch (result?.action) {
                              case TaskChildDetailAction.complete:
                                onCompleteMission(
                                  mission,
                                  logForMission(mission.id),
                                  missionAnchorKeyFor('missions:${mission.id}'),
                                  note: result?.note,
                                );
                              case TaskChildDetailAction.cancelSubmission:
                                onCancelMissionSubmission(
                                  mission,
                                  logForMission(mission.id),
                                );
                              case TaskChildDetailAction.undoCompletion:
                                final approvedLog = logForMission(mission.id);
                                if (approvedLog != null) {
                                  onUndoMissionCompletion(mission, approvedLog);
                                }
                              case null:
                                break;
                            }
                          },
                        ),
                      ),
                      if (mission !=
                          missions
                              .where((item) => item.timeGroup == group)
                              .last)
                        const Divider(height: 1),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: ZeniSpacing.spaceSection),
            ],
          ],
        ),
      ),
    );

    if (onRefresh == null) {
      return content;
    }

    return RefreshIndicator(onRefresh: onRefresh!, child: content);
  }
}
