import 'package:flutter/material.dart';

import '../../theme/zeni_colors.dart';

class DangerActionText extends StatelessWidget {
  const DangerActionText({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.delete_outline_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: TextButton.styleFrom(foregroundColor: ZeniColors.error),
    );
  }
}
