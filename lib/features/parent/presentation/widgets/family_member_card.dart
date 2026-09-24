import 'package:flutter/material.dart';

import '../../../../core/domain/zeni_enums.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/theme/zeni_typography.dart';
import '../../../../core/widgets/base/zeni_avatar.dart';
import '../../../family/data/models/family_member.dart';

class FamilyMemberCard extends StatelessWidget {
  const FamilyMemberCard({super.key, required this.member, this.onTap});

  final FamilyMember member;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final typography = ZeniTypography.of(context);
    return Semantics(
      container: true,
      label: member.isOwner
          ? '${member.name}, ${member.role.label}, dono'
          : '${member.name}, ${member.role.label}',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          key: Key('parent-family-member-${member.id}'),
          padding: const EdgeInsets.symmetric(
            horizontal: ZeniSpacing.spaceCard,
            vertical: ZeniSpacing.spaceControl,
          ),
          child: Row(
            children: [
              ZeniAvatar(
                label: member.name,
                emoji: member.role == ZeniUserRole.parent ? '👤' : '⭐',
                size: 52,
              ),
              const SizedBox(width: ZeniSpacing.spaceControl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: typography.cardTitle),
                    const SizedBox(height: ZeniSpacing.spaceInlineTight),
                    Text(
                      member.isOwner
                          ? '${member.role.label} · Dono'
                          : member.role.label,
                      style: typography.metadata,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
