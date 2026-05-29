import 'package:flutter/material.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';

class AuthProviderButton extends StatelessWidget {
  static const double _buttonHeight = 52;
  static const double _leadingSlotWidth = 28;

  const AuthProviderButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final Widget? leading;

  factory AuthProviderButton.google({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
  }) {
    return AuthProviderButton(
      key: key,
      label: label,
      onPressed: onPressed,
      backgroundColor: Colors.white,
      foregroundColor: ZeniColors.text,
      borderColor: ZeniColors.border,
      leading: Image.asset(
        'assets/icons/google_g_logo.png',
        width: 18,
        height: 18,
        errorBuilder: (_, _, _) => const SizedBox(width: 18, height: 18),
      ),
    );
  }

  factory AuthProviderButton.apple({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
  }) {
    return AuthProviderButton(
      key: key,
      label: label,
      onPressed: onPressed,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      borderColor: Colors.black,
      leading: const Icon(Icons.apple, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _buttonHeight,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor ?? Colors.transparent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: ZeniSpacing.lg),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            SizedBox(
              width: _leadingSlotWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: leading ?? const SizedBox.shrink(),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: _leadingSlotWidth),
          ],
        ),
      ),
    );
  }
}
