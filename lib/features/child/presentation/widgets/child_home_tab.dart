import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../rewards/data/models/reward.dart';
import '../../../rewards/data/models/reward_request.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/models/mission_log.dart';
import '../../../tasks/presentation/widgets/task_child_detail_sheet.dart';
import '../widgets/child_birthday_card.dart';
import '../widgets/child_bonus_mission_card.dart';
import '../widgets/child_daily_message_card.dart';
import '../widgets/child_daily_progress_card.dart';
import '../widgets/child_next_mission_card.dart';
import '../widgets/child_reward_nudge_card.dart';

class ChildHomeTab extends StatelessWidget {
  const ChildHomeTab({
    super.key,
    required this.child,
    required this.missions,
    required this.todayLogs,
    required this.rewards,
    required this.pendingRewardRequests,
    required this.logForMission,
    required this.missionAnchorKeyFor,
    required this.onCompleteMission,
    required this.onCancelMissionSubmission,
    required this.onOpenRewards,
  });

  final ChildProfile child;
  final List<Mission> missions;
  final List<MissionLog> todayLogs;
  final List<Reward> rewards;
  final List<RewardRequest> pendingRewardRequests;
  final MissionLog? Function(String missionId) logForMission;
  final GlobalKey Function(String missionId) missionAnchorKeyFor;
  final void Function(Mission mission, MissionLog? log, GlobalKey? sourceKey)
  onCompleteMission;
  final void Function(Mission mission, MissionLog? log)
  onCancelMissionSubmission;
  final VoidCallback onOpenRewards;

  @override
  Widget build(BuildContext context) {
    final approvedLogs = todayLogs
        .where((log) => log.status == MissionLogStatus.approved)
        .length;
    final awaitingLogs = todayLogs
        .where((log) => log.status == MissionLogStatus.awaitingApproval)
        .length;

    final pendingMissions = missions
        .where(
          (mission) =>
              (logForMission(mission.id)?.status ?? MissionLogStatus.pending) ==
              MissionLogStatus.pending,
        )
        .toList();

    final nextMission = pendingMissions.isEmpty ? null : pendingMissions.first;
    final bonusMission = _findBonusMission(
      pendingMissions: pendingMissions,
      nextMission: nextMission,
    );
    final pendingRewardCount = pendingRewardRequests.length;
    final rewardNudge = _findRewardNudge();
    final isBirthday = _isBirthday(child);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ZeniSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBirthday)
            ChildBirthdayCard(child: child)
          else
            ChildDailyMessageCard(
              child: child,
              totalMissions: missions.length,
              completedMissions: approvedLogs,
              awaitingApprovalMissions: awaitingLogs,
            ),
          const SizedBox(height: ZeniSpacing.lg),
          ChildDailyProgressCard(
            completed: approvedLogs,
            awaitingApproval: awaitingLogs,
            total: missions.length,
          ),
          if (pendingRewardCount > 0) ...[
            const SizedBox(height: ZeniSpacing.lg),
            _ChildPendingRewardStatusCard(
              count: pendingRewardCount,
              onTap: onOpenRewards,
            ),
          ],
          if (nextMission != null) ...[
            const SizedBox(height: ZeniSpacing.lg),
            KeyedSubtree(
              key: missionAnchorKeyFor('home:${nextMission.id}'),
              child: ChildNextMissionCard(
                mission: nextMission,
                log: logForMission(nextMission.id),
                onOpen: () {
                  _openMissionDetails(context, nextMission);
                },
                onCancelSubmission: () {
                  onCancelMissionSubmission(
                    nextMission,
                    logForMission(nextMission.id),
                  );
                },
              ),
            ),
          ],
          if (bonusMission != null) ...[
            const SizedBox(height: ZeniSpacing.lg),
            KeyedSubtree(
              key: missionAnchorKeyFor('home:${bonusMission.id}'),
              child: ChildBonusMissionCard(
                mission: bonusMission,
                onOpen: () {
                  _openMissionDetails(context, bonusMission);
                },
              ),
            ),
          ],
          if (rewardNudge != null) ...[
            const SizedBox(height: ZeniSpacing.lg),
            ChildRewardNudgeCard(
              reward: rewardNudge,
              currentBalance: child.starBalance,
              onTap: onOpenRewards,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openMissionDetails(
    BuildContext context,
    Mission mission,
  ) async {
    final log = logForMission(mission.id);

    final action = await showModalBottomSheet<TaskChildDetailAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: TaskChildDetailSheet(mission: mission, log: log),
        );
      },
    );

    if (!context.mounted) return;

    switch (action) {
      case TaskChildDetailAction.complete:
        onCompleteMission(
          mission,
          logForMission(mission.id),
          missionAnchorKeyFor('home:${mission.id}'),
        );
      case TaskChildDetailAction.cancelSubmission:
        onCancelMissionSubmission(mission, logForMission(mission.id));
      case null:
        break;
    }
  }

  Mission? _findBonusMission({
    required List<Mission> pendingMissions,
    required Mission? nextMission,
  }) {
    final candidates =
        pendingMissions
            .where(
              (mission) => mission.id != nextMission?.id && mission.stars >= 15,
            )
            .toList()
          ..sort((a, b) => b.stars.compareTo(a.stars));

    if (candidates.isEmpty) return null;

    return candidates.first;
  }

  Reward? _findRewardNudge() {
    final sortedRewards = [...rewards]
      ..sort((a, b) => a.cost.compareTo(b.cost));

    for (final reward in sortedRewards) {
      if (reward.cost >= child.starBalance) {
        return reward;
      }
    }

    return sortedRewards.isEmpty ? null : sortedRewards.first;
  }

  bool _isBirthday(ChildProfile profile) {
    final birthDate = profile.birthDate;
    if (birthDate == null) return false;

    final today = DateTime.now();
    return today.day == birthDate.day && today.month == birthDate.month;
  }
}

class _ChildPendingRewardStatusCard extends StatelessWidget {
  const _ChildPendingRewardStatusCard({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = count == 1
        ? 'Você tem mimo aguardando aprovação 🎁'
        : 'Você tem $count mimos aguardando aprovação 🎁';

    return ZeniCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ZeniColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: ZeniColors.primaryDark,
            ),
          ),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  'O responsável vai revisar seu pedido.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
