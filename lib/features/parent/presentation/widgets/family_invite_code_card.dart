import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_icon_action_button.dart';
import '../../../family/data/models/family.dart';

class FamilyInviteCodeCard extends StatelessWidget {
  const FamilyInviteCodeCard({super.key, required this.family, this.onCopy});

  final Family family;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      child: Row(
        children: [
          const Text('🔗', style: TextStyle(fontSize: 36)),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Código da família',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  family.inviteCode,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: ZeniColors.primaryDark,
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
