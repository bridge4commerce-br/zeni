import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
import '../../../../core/widgets/base/zeni_choice_chip.dart';
import '../../../family/data/models/child_profile.dart';
import 'parent_mission_typography.dart';

class ParentChildFilterChips extends StatelessWidget {
  const ParentChildFilterChips({
    super.key,
    required this.children,
    required this.selectedChildId,
    required this.onChanged,
    this.useZeniV2 = false,
  });

  final List<ChildProfile> children;
  final String? selectedChildId;
  final ValueChanged<String?> onChanged;
  final bool useZeniV2;

  @override
  Widget build(BuildContext context) {
    if (useZeniV2) {
      return SingleChildScrollView(
        key: const Key('parent-missions-child-filters'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ZeniChoiceChip(
              label: 'Todas',
              selected: selectedChildId == null,
              onSelected: (_) => onChanged(null),
              mode: ZeniVisualMode.parent,
            ),
            const SizedBox(width: ZeniSpacing.spaceInline),
            for (final child in children) ...[
              ZeniChoiceChip(
                label: child.name,
                icon: Text(child.emoji),
                selected: selectedChildId == child.id,
                onSelected: (_) => onChanged(child.id),
                mode: ZeniVisualMode.parent,
              ),
              const SizedBox(width: ZeniSpacing.spaceInline),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: Text(
              'Todas',
              style: ParentMissionTypography.filterLabel(context),
            ),
            selected: selectedChildId == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: ZeniSpacing.sm),
          for (final child in children) ...[
            ChoiceChip(
              avatar: Text(child.emoji),
              label: Text(
                child.name,
                style: ParentMissionTypography.filterLabel(context),
              ),
              selected: selectedChildId == child.id,
              onSelected: (_) => onChanged(child.id),
            ),
            const SizedBox(width: ZeniSpacing.sm),
          ],
        ],
      ),
    );
  }
}
