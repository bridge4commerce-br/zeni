import 'package:flutter/material.dart';

import '../../theme/zeni_colors.dart';
import '../../theme/zeni_radius.dart';

class ZeniAvatar extends StatelessWidget {
  const ZeniAvatar({
    super.key,
    required this.label,
    this.emoji,
    this.imageProvider,
    this.size = 56,
    this.backgroundColor,
  });

  final String label;
  final String? emoji;
  final ImageProvider? imageProvider;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final fallbackColor =
        backgroundColor ?? ZeniColors.primary.withValues(alpha: 0.14);

    return Semantics(
      label: label,
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fallbackColor,
          borderRadius: BorderRadius.circular(ZeniRadius.pill),
          image: imageProvider == null
              ? null
              : DecorationImage(image: imageProvider!, fit: BoxFit.cover),
        ),
        alignment: Alignment.center,
        child: imageProvider != null
            ? null
            : Text(
                emoji ?? _initials(label),
                style: TextStyle(
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w800,
                  color: ZeniColors.primaryDark,
                ),
              ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}
