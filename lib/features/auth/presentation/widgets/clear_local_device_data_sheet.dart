import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/inputs/zeni_text_input.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';

class ClearLocalDeviceDataSheet extends StatefulWidget {
  const ClearLocalDeviceDataSheet({super.key, required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<ClearLocalDeviceDataSheet> createState() =>
      _ClearLocalDeviceDataSheetState();
}

class _ClearLocalDeviceDataSheetState extends State<ClearLocalDeviceDataSheet> {
  final TextEditingController _confirmController = TextEditingController();
  bool _isClearing = false;
  String? _errorText;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConfirmationValid = _confirmController.text.trim() == 'APAGAR';
    return ZeniModalSheetContainer(
      title: 'Apagar dados deste aparelho',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Apagar dados deste aparelho remove crianças, missões, mimos, histórico e saldo salvos localmente. Os dados da nuvem não serão apagados.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.md),
          Text(
            'Digite APAGAR para confirmar. Esta ação reinicia o app neste aparelho.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ZeniColors.mutedText),
          ),
          const SizedBox(height: ZeniSpacing.lg),
          ZeniTextInput(
            key: const Key('clear-local-data-confirm-input'),
            controller: _confirmController,
            label: 'Confirmação',
            hint: 'Digite APAGAR',
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() => _errorText = null),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: ZeniSpacing.sm),
            Text(
              _errorText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: ZeniSpacing.lg),
          ZeniSecondaryButton(
            label: 'Cancelar',
            onPressed: _isClearing
                ? null
                : () => Navigator.of(context).pop(false),
          ),
          const SizedBox(height: ZeniSpacing.sm),
          ZeniPrimaryButton(
            label: _isClearing ? 'Apagando...' : 'Apagar dados deste aparelho',
            onPressed: (_isClearing || !isConfirmationValid) ? null : _confirm,
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() {
      _isClearing = true;
      _errorText = null;
    });
    try {
      await widget.onConfirm();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isClearing = false;
        _errorText =
            'Não foi possível apagar os dados deste aparelho agora. Tente novamente.';
      });
    }
  }
}
