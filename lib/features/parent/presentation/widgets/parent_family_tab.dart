import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/feedback/zeni_success_popup.dart';
import '../../../balance/data/models/star_ledger_entry.dart';
import '../../../family/data/models/child_profile.dart';
import '../../../family/data/models/family.dart';
import '../../../family/data/models/family_member.dart';
import '../../../rewards/data/models/reward.dart';
import '../../../tasks/data/models/mission.dart';
import 'family_invite_code_card.dart';
import 'family_member_card.dart';
import 'parent_archived_child_card.dart';
import 'parent_child_management_sheet.dart';
import 'parent_child_summary_card.dart';
import 'parent_empty_state_card.dart';

class ParentFamilyTab extends StatelessWidget {
  const ParentFamilyTab({
    super.key,
    required this.family,
    required this.children,
    required this.members,
    required this.activeMissions,
    required this.activeRewards,
    required this.ledgerEntries,
    required this.onAddChild,
    required this.onEditChild,
    required this.onArchiveChild,
    required this.onRestoreChild,
  });

  final Family family;
  final List<ChildProfile> children;
  final List<FamilyMember> members;
  final List<Mission> activeMissions;
  final List<Reward> activeRewards;
  final List<StarLedgerEntry> ledgerEntries;
  final VoidCallback onAddChild;
  final ValueChanged<ChildProfile> onEditChild;
  final ValueChanged<ChildProfile> onArchiveChild;
  final ValueChanged<ChildProfile> onRestoreChild;

  @override
  Widget build(BuildContext context) {
    final activeChildren = children.where((child) => child.isActive).toList();
    final archivedChildren = children.where((child) => !child.isActive).toList();
    final responsibleMembers = members
        .where((member) => member.role == ZeniUserRole.parent)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ZeniSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Família', style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: ZeniSpacing.sm),
          Text(
            'Gerencie crianças, responsáveis e o convite da família.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.xl),
          Text(
            'Perfis das crianças',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ZeniSpacing.md),
          if (activeChildren.isEmpty)
            const ParentEmptyStateCard(
              emoji: '👧',
              title: 'Nenhuma criança ativa',
              message: 'Adicione ou restaure uma criança para começar.',
            )
          else
            for (final child in activeChildren) ...[
              ParentChildSummaryCard(
                child: child,
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.viewInsetsOf(context).bottom,
                        ),
                        child: ParentChildManagementSheet(
                          child: child,
                          missions: activeMissions,
                          rewards: activeRewards,
                          ledgerEntries: ledgerEntries,
                          onEditProfile: () {
                            Navigator.of(context).pop();
                            onEditChild(child);
                          },
                          onArchiveProfile: () {
                            Navigator.of(context).pop();
                            onArchiveChild(child);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: ZeniSpacing.md),
            ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Adicionar criança'),
              onPressed: onAddChild,
            ),
          ),
          const SizedBox(height: ZeniSpacing.xl),
          Text('Responsáveis', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: ZeniSpacing.md),
          if (responsibleMembers.isEmpty)
            const ParentEmptyStateCard(
              emoji: '👤',
              title: 'Nenhum responsável',
              message: 'Os responsáveis da família aparecerão aqui.',
            )
          else
            for (final member in responsibleMembers) ...[
              FamilyMemberCard(member: member),
              const SizedBox(height: ZeniSpacing.md),
            ],
          const SizedBox(height: ZeniSpacing.xl),
          Text(
            'Código da família',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: ZeniSpacing.md),
          FamilyInviteCodeCard(
            family: family,
            onCopy: () {
              ZeniSuccessPopup.show(
                context,
                title: 'Código copiado',
                message: 'Depois vamos conectar isso à área de transferência.',
              );
            },
          ),
          if (archivedChildren.isNotEmpty) ...[
            const SizedBox(height: ZeniSpacing.xl),
            Text(
              'Crianças arquivadas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: ZeniSpacing.md),
            for (final child in archivedChildren) ...[
              ParentArchivedChildCard(
                child: child,
                onRestore: () => onRestoreChild(child),
              ),
              const SizedBox(height: ZeniSpacing.md),
            ],
          ],
        ],
      ),
    );
  }
}
