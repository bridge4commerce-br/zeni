import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ParentPinDialog extends StatefulWidget {
  const ParentPinDialog.create({super.key, this.hasExistingPin = false})
    : mode = ParentPinDialogMode.create;

  const ParentPinDialog.verify({super.key})
    : mode = ParentPinDialogMode.verify,
      hasExistingPin = false;

  final ParentPinDialogMode mode;
  final bool hasExistingPin;

  @override
  State<ParentPinDialog> createState() => _ParentPinDialogState();
}

class _ParentPinDialogState extends State<ParentPinDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorText;

  bool get _isCreateMode => widget.mode == ParentPinDialogMode.create;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isCreateMode ? 'PIN do responsável' : 'Digite seu PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isCreateMode
                ? widget.hasExistingPin
                      ? 'Escolha um novo PIN de 4 dígitos para proteger o modo responsável.'
                      : 'Defina um PIN de 4 dígitos para proteger o modo responsável.'
                : 'Use seu PIN de 4 dígitos para continuar.',
          ),
          const SizedBox(height: 16),
          _PinTextField(
            key: const Key('parent-pin-input'),
            controller: _pinController,
            label: _isCreateMode ? 'Novo PIN' : 'PIN',
            autofocus: true,
            onChanged: _clearError,
          ),
          if (_isCreateMode) ...[
            const SizedBox(height: 12),
            _PinTextField(
              key: const Key('parent-pin-confirm-input'),
              controller: _confirmController,
              label: 'Confirmar PIN',
              autofocus: false,
              onChanged: _clearError,
            ),
          ],
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isCreateMode ? 'Salvar PIN' : 'Entrar'),
        ),
      ],
    );
  }

  void _clearError(String _) {
    if (_errorText == null) return;
    setState(() {
      _errorText = null;
    });
  }

  void _submit() {
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      setState(() {
        _errorText = 'Digite um PIN com 4 números.';
      });
      return;
    }

    if (_isCreateMode && pin != _confirmController.text.trim()) {
      setState(() {
        _errorText = 'Os PINs não coincidem.';
      });
      return;
    }

    Navigator.of(context).pop(pin);
  }
}

class _PinTextField extends StatelessWidget {
  const _PinTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.autofocus,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      obscuringCharacter: '•',
      maxLength: 4,
      autofocus: autofocus,
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
    );
  }
}

enum ParentPinDialogMode { create, verify }
