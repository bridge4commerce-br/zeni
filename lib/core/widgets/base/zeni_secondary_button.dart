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
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
    final child = icon == null
        ? labelText
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Flexible(child: labelText),
            ],
          );

    final button = OutlinedButton(onPressed: onPressed, child: child);

    if (!fullWidth) return button;

    return SizedBox(width: double.infinity, child: button);
  }
}
