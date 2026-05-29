import 'package:flutter/material.dart';

class ZeniSecondaryButton extends StatelessWidget {
  const ZeniSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(icon), const SizedBox(width: 8), Text(label)],
          );

    final button = OutlinedButton(onPressed: onPressed, child: child);

    if (!fullWidth) return button;

    return SizedBox(width: double.infinity, child: button);
  }
}
