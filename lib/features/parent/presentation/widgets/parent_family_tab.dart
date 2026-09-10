import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/zeni_button.dart';
import '../../../../core/widgets/base/zeni_surface.dart';
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
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    final windowClass = ZeniResponsive.windowClass(context);
    final isWide =
        windowClass == ZeniWindowClass.expanded ||
        windowClass == ZeniWindowClass.large;
    final activeChildren = children.where((child) => child.isActive).toList();
    final archivedChildren = children
        .where((child) => !child.isActive)
        .toList();
    final responsibleMembers = members
        .where((member) => member.role == ZeniUserRole.parent)
        .toList();

    final childrenSection = Column(
      key: const Key('parent-family-children-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Perfis das crianças', style: typography.sectionTitle),
        const SizedBox(height: ZeniSpacing.spaceCard),
        if (activeChildren.isEmpty)
          const _FamilyEmptyState(
            icon: Icons.child_care_outlined,
            title: 'Nenhuma criança ativa',
            message: 'Adicione ou restaure uma criança para começar.',
          )
        else
          ZeniSurface(
            key: const Key('parent-family-children-list'),
            role: ZeniSurfaceRole.grouped,
            mode: ZeniVisualMode.parent,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < activeChildren.length; index++) ...[
                  ParentChildSummaryCard(
                    child: activeChildren[index],
                    onTap: () =>
                        _openChildManagement(context, activeChildren[index]),
                  ),
                  if (index < activeChildren.length - 1)
                    Divider(height: 1, color: colors.borderSubtle),
                ],
              ],
            ),
          ),
        const SizedBox(height: ZeniSpacing.spaceCard),
        ZeniButton(
          label: 'Adicionar criança',
          icon: Icons.person_add_alt_1_rounded,
          role: ZeniButtonRole.primary,
          mode: ZeniVisualMode.parent,
          onPressed: onAddChild,
        ),
      ],
    );
    final detailsSection = Column(
      key: const Key('parent-family-details-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Responsáveis', style: typography.sectionTitle),
        const SizedBox(height: ZeniSpacing.spaceCard),
        if (responsibleMembers.isEmpty)
          const _FamilyEmptyState(
            icon: Icons.person_outline_rounded,
            title: 'Nenhum responsável',
            message: 'Os responsáveis da família aparecerão aqui.',
          )
        else
          ZeniSurface(
            key: const Key('parent-family-members-list'),
            role: ZeniSurfaceRole.grouped,
            mode: ZeniVisualMode.parent,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < responsibleMembers.length;
                  index++
                ) ...[
                  FamilyMemberCard(member: responsibleMembers[index]),
                  if (index < responsibleMembers.length - 1)
                    Divider(height: 1, color: colors.borderSubtle),
                ],
              ],
            ),
          ),
        const SizedBox(height: ZeniSpacing.spaceSection),
        Text('Código da família', style: typography.sectionTitle),
        const SizedBox(height: ZeniSpacing.spaceCard),
        ZeniSurface(
          role: ZeniSurfaceRole.highlight,
          mode: ZeniVisualMode.parent,
          padding: EdgeInsets.zero,
          child: FamilyInviteCodeCard(
            family: family,
            onCopy: () => ZeniSuccessPopup.show(
              context,
              title: 'Código copiado',
              message: 'Depois vamos conectar isso à área de transferência.',
            ),
          ),
        ),
        if (archivedChildren.isNotEmpty) ...[
          const SizedBox(height: ZeniSpacing.spaceSection),
          Text('Crianças arquivadas', style: typography.sectionTitle),
          const SizedBox(height: ZeniSpacing.spaceCard),
          ZeniSurface(
            key: const Key('parent-family-archived-list'),
            role: ZeniSurfaceRole.grouped,
            mode: ZeniVisualMode.parent,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < archivedChildren.length;
                  index++
                ) ...[
                  ParentArchivedChildCard(
                    child: archivedChildren[index],
                    onRestore: () => onRestoreChild(archivedChildren[index]),
                  ),
                  if (index < archivedChildren.length - 1)
                    Divider(height: 1, color: colors.borderSubtle),
                ],
              ],
            ),
          ),
        ],
      ],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: ZeniSpacing.spaceSection,
        bottom: ZeniSpacing.spaceCanvas + MediaQuery.paddingOf(context).bottom,
      ),
      child: ZeniPageFrame(
        width: ZeniPageWidth.dashboard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Família', style: typography.pageTitle),
            const SizedBox(height: ZeniSpacing.spaceInline),
            Text(
              'Gerencie crianças, responsáveis e o convite da família.',
              style: typography.body,
            ),
            const SizedBox(height: ZeniSpacing.spaceSection),
            if (isWide)
              Row(
                key: const Key('parent-family-wide-layout'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: childrenSection),
                  const SizedBox(width: ZeniSpacing.spaceGroup),
                  Expanded(child: detailsSection),
                ],
              )
            else
              Column(
                key: const Key('parent-family-single-layout'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  childrenSection,
                  const SizedBox(height: ZeniSpacing.spaceSection),
                  detailsSection,
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _openChildManagement(BuildContext context, ChildProfile child) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: ParentChildManagementSheet(
          child: child,
          missions: activeMissions,
          rewards: activeRewards,
          ledgerEntries: ledgerEntries,
          onEditProfile: () {
            Navigator.of(sheetContext).pop();
            onEditChild(child);
          },
          onArchiveProfile: () {
            Navigator.of(sheetContext).pop();
            onArchiveChild(child);
          },
        ),
      ),
    );
  }
}

class _FamilyEmptyState extends StatelessWidget {
  const _FamilyEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    return Row(
      children: [
        Icon(icon, color: colors.textSecondary),
        const SizedBox(width: ZeniSpacing.spaceControl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: typography.cardTitle),
              const SizedBox(height: ZeniSpacing.spaceInlineTight),
              Text(message, style: typography.metadata),
            ],
          ),
        ),
      ],
    );
  }
}
