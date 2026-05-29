import 'package:flutter/material.dart';

import '../../theme/zeni_radius.dart';
import '../../theme/zeni_spacing.dart';

class ZeniModalSheetContainer extends StatelessWidget {
  const ZeniModalSheetContainer({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(ZeniSpacing.xl),
  });

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        padding: padding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: ZeniRadius.sheet,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(ZeniRadius.pill),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: ZeniSpacing.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(title!, style: textTheme.titleLarge),
              ),
            ],
            const SizedBox(height: ZeniSpacing.lg),
            Flexible(fit: FlexFit.loose, child: child),
          ],
        ),
      ),
    );
  }
}
