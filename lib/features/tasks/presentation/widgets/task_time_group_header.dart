import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_spacing.dart';

class TaskTimeGroupHeader extends StatelessWidget {
  const TaskTimeGroupHeader({super.key, required this.group});

  final MissionTimeGroup group;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(group.emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: ZeniSpacing.sm),
        Text(group.label, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
