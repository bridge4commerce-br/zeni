import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_spacing.dart';
import '../../../family/data/models/child_profile.dart';

class ParentChildFilterChips extends StatelessWidget {
  const ParentChildFilterChips({
    super.key,
    required this.children,
    required this.selectedChildId,
    required this.onChanged,
  });

  final List<ChildProfile> children;
  final String? selectedChildId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Todas'),
            selected: selectedChildId == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: ZeniSpacing.sm),
          for (final child in children) ...[
            ChoiceChip(
              avatar: Text(child.emoji),
              label: Text(child.name),
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
