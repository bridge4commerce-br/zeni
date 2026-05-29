import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_avatar.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../family/data/models/family_member.dart';

class FamilyMemberCard extends StatelessWidget {
  const FamilyMemberCard({super.key, required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    return ZeniCard(
      child: Row(
        children: [
          ZeniAvatar(
            label: member.name,
            emoji: member.role == ZeniUserRole.parent ? '👤' : '⭐',
            size: 52,
          ),
          const SizedBox(width: ZeniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: ZeniSpacing.xs),
                Text(
                  member.isOwner
                      ? '${member.role.label} · Dono'
                      : member.role.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
