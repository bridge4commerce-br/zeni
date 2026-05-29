import 'package:flutter/material.dart';

class ZeniFab extends StatelessWidget {
  const ZeniFab({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.label,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return FloatingActionButton(
        tooltip: tooltip,
        onPressed: onPressed,
        child: Icon(icon),
      );
    }

    return FloatingActionButton.extended(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label!),
    );
  }
}
