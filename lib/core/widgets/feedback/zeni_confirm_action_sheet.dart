import 'package:flutter/material.dart';

import '../../theme/zeni_colors.dart';
import '../../theme/zeni_spacing.dart';
import '../base/zeni_primary_button.dart';
import '../base/zeni_secondary_button.dart';
import '../layout/zeni_modal_sheet_container.dart';

class ZeniConfirmActionSheet extends StatelessWidget {
  const ZeniConfirmActionSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancelar',
    this.isDanger = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return ZeniModalSheetContainer(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.xl),
          if (isDanger)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZeniColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(confirmLabel),
              ),
            )
          else
            ZeniPrimaryButton(
              label: confirmLabel,
              icon: Icons.check_rounded,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          const SizedBox(height: ZeniSpacing.md),
          ZeniSecondaryButton(
            label: cancelLabel,
            icon: Icons.close_rounded,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
