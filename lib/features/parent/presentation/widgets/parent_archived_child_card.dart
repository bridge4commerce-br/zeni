import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_avatar.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../family/data/models/child_profile.dart';

class ParentArchivedChildCard extends StatelessWidget {
  const ParentArchivedChildCard({
    super.key,
    required this.child,
    required this.onRestore,
  });

  final ChildProfile child;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ZeniAvatar(label: child.name, emoji: child.emoji, size: 56),
              const SizedBox(width: ZeniSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: ZeniSpacing.xs),
                    Text(
                      'Perfil arquivado',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ZeniColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeniSpacing.lg),
          const Divider(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Restaurar criança'),
              onPressed: onRestore,
            ),
          ),
        ],
      ),
    );
  }
}
