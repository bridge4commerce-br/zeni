import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/widgets/base/zeni_avatar.dart';
import '../../../../core/widgets/base/zeni_button.dart';
import '../../../../core/theme/zeni_visual_mode.dart';
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
    final typography = ZeniTypography.of(context);
    return Padding(
      key: Key('parent-family-archived-child-${child.id}'),
      padding: const EdgeInsets.all(ZeniSpacing.spaceCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ZeniAvatar(label: child.name, emoji: child.emoji, size: 56),
              const SizedBox(width: ZeniSpacing.spaceControl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.name, style: typography.cardTitle),
                    const SizedBox(height: ZeniSpacing.spaceInlineTight),
                    Text('Perfil arquivado', style: typography.metadata),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ZeniSpacing.spaceCard),
          const Divider(),
          ZeniButton(
            label: 'Restaurar criança',
            icon: Icons.restore_rounded,
            role: ZeniButtonRole.tertiary,
            mode: ZeniVisualMode.parent,
            fullWidth: false,
            onPressed: onRestore,
          ),
        ],
      ),
    );
  }
}
