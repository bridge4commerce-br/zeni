import 'package:flutter/material.dart';

import '../../theme/zeni_colors.dart';

enum ZeniIconActionTone { primary, neutral, danger }

class ZeniIconActionButton extends StatelessWidget {
  const ZeniIconActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.tone = ZeniIconActionTone.neutral,
    this.size = 44,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final ZeniIconActionTone tone;
  final double size;

  Color _foregroundColor(BuildContext context) {
    return switch (tone) {
      ZeniIconActionTone.primary => ZeniColors.primaryDark,
      ZeniIconActionTone.neutral =>
        Theme.of(context).textTheme.bodyLarge?.color ?? ZeniColors.text,
      ZeniIconActionTone.danger => ZeniColors.error,
    };
  }

  Color _backgroundColor(BuildContext context) {
    final color = _foregroundColor(context);
    return color.withValues(alpha: 0.10);
  }

  @override
  Widget build(BuildContext context) {
    final foregroundColor = _foregroundColor(context);

    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: _backgroundColor(context),
          foregroundColor: foregroundColor,
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.32),
          disabledBackgroundColor: foregroundColor.withValues(alpha: 0.06),
        ),
        icon: Icon(icon),
      ),
    );
  }
}
