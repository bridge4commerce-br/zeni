import 'package:flutter/material.dart';

import '../../theme/zeni_radius.dart';
import '../../theme/zeni_shadows.dart';
import '../../theme/zeni_spacing.dart';

class ZeniCard extends StatelessWidget {
  const ZeniCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(ZeniSpacing.lg),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: ZeniRadius.card,
        boxShadow: ZeniShadows.card,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: ZeniRadius.card, onTap: onTap, child: card),
    );
  }
}
