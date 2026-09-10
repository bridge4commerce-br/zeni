import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_icon_action_button.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../family/data/models/family.dart';

class FamilyInviteCodeCard extends StatelessWidget {
  const FamilyInviteCodeCard({super.key, required this.family, this.onCopy});

  final Family family;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    final colors = context.zeniColors;
    return Padding(
      padding: const EdgeInsets.all(ZeniSpacing.spaceCard),
      child: Row(
        children: [
          const Text('🔗', style: TextStyle(fontSize: 36)),
          const SizedBox(width: ZeniSpacing.spaceControl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Código da família', style: typography.cardTitle),
                const SizedBox(height: ZeniSpacing.spaceInlineTight),
                Text(
                  family.inviteCode,
                  style: typography.sectionTitle.copyWith(
                    color: colors.actionPrimary,
                  ),
                ),
              ],
            ),
          ),
          ZeniIconActionButton(
            icon: Icons.copy_rounded,
            tooltip: 'Copiar código',
            tone: ZeniIconActionTone.primary,
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}
