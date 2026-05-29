import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_avatar.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../family/data/models/child_profile.dart';

class ChildProfileSummaryCard extends StatelessWidget {
  const ChildProfileSummaryCard({super.key, required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      child: Row(
        children: [
          ZeniAvatar(label: child.name, emoji: child.emoji, size: 72),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  '${child.streakCount} dias de sequência',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ),
          ),
          const Text('🔥', style: TextStyle(fontSize: 30)),
        ],
      ),
    );
  }
}
