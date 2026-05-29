import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/inputs/zeni_text_input.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
import '../../data/repositories/zeni_auth_repository.dart';
import '../providers/zeni_auth_providers.dart';
import 'auth_provider_button.dart';

enum AuthAccountAction { emailSignIn, emailSignUp, google, apple }

class AuthAccountSheet extends ConsumerStatefulWidget {
  const AuthAccountSheet({super.key, required this.isSupabaseConfigured});

  final bool isSupabaseConfigured;

  @override
  ConsumerState<AuthAccountSheet> createState() => _AuthAccountSheetState();
}

class _AuthAccountSheetState extends ConsumerState<AuthAccountSheet> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  AuthAccountAction? _activeAction;
  String? _emailError;
  String? _passwordError;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGoogleAvailable = ref.watch(googleSignInAvailableProvider);
    final isAppleAvailable = ref.watch(appleSignInAvailableProvider);
    final isBusy = _activeAction != null;

    return ZeniModalSheetContainer(
      title: 'Conta da família',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seu app continua funcionando neste aparelho. A conta será usada futuramente para proteger e sincronizar os dados da família.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
            ),
            if (!widget.isSupabaseConfigured) ...[
              const SizedBox(height: ZeniSpacing.md),
              Text(
                'A autenticação ainda não está disponível neste build. Você pode continuar usando o Zeni localmente.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: ZeniSpacing.xl),
            ZeniTextInput(
              key: const Key('auth-email-input'),
              controller: _emailController,
              label: 'E-mail',
              hint: 'responsavel@email.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.none,
              errorText: _emailError,
            ),
            const SizedBox(height: ZeniSpacing.md),
            ZeniTextInput(
              key: const Key('auth-password-input'),
              controller: _passwordController,
              label: 'Senha',
              hint: 'Use pelo menos 6 caracteres',
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.none,
              obscureText: true,
              errorText: _passwordError,
            ),
            if (_formError != null) ...[
              const SizedBox(height: ZeniSpacing.md),
              Text(
                _formError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: ZeniSpacing.xl),
            ZeniSecondaryButton(
              label: _activeAction == AuthAccountAction.emailSignIn
                  ? 'Entrando...'
                  : 'Entrar',
              onPressed: isBusy ? null : _submitSignIn,
            ),
            const SizedBox(height: ZeniSpacing.md),
            ZeniPrimaryButton(
              label: _activeAction == AuthAccountAction.emailSignUp
                  ? 'Criando conta...'
                  : 'Criar conta',
              onPressed: isBusy ? null : _submitSignUp,
            ),
            const SizedBox(height: ZeniSpacing.md),
            AuthProviderButton.google(
              key: const Key('auth-google-button'),
              label: _activeAction == AuthAccountAction.google
                  ? 'Conectando com Google...'
                  : 'Entrar com Google',
              onPressed: isBusy
                  ? null
                  : () => _submitGoogle(isGoogleAvailable),
            ),
            if (isAppleAvailable) ...[
              const SizedBox(height: ZeniSpacing.md),
              AuthProviderButton.apple(
                key: const Key('auth-apple-button'),
                label: _activeAction == AuthAccountAction.apple
                    ? 'Conectando com Apple...'
                    : 'Entrar com Apple',
                onPressed: isBusy ? null : _submitApple,
              ),
            ],
            const SizedBox(height: ZeniSpacing.md),
            Text(
              'Com e-mail e senha, a conta é criada com confirmação por e-mail.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
            ),
            const SizedBox(height: ZeniSpacing.xs),
            Text(
              'Google e Apple são opcionais e não alteram os dados locais deste aparelho.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: ZeniColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitSignUp() async {
    await _submit(
      AuthAccountAction.emailSignUp,
      () => ref
          .read(zeniAuthControllerProvider)
          .signUpWithEmailPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
    );
  }

  Future<void> _submitSignIn() async {
    await _submit(
      AuthAccountAction.emailSignIn,
      () => ref
          .read(zeniAuthControllerProvider)
          .signInWithEmailPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
    );
  }

  Future<void> _submitGoogle(bool isGoogleAvailable) async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _formError = null;
      _activeAction = AuthAccountAction.google;
    });

    final result = await ref.read(zeniAuthControllerProvider).signInWithGoogle();
    if (!mounted) return;

    setState(() {
      _activeAction = null;
      _formError = result.message ??
          (!isGoogleAvailable
              ? 'Google Sign-In não está configurado neste app.'
              : null);
    });

    if (result.isSuccess && result.user != null) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _submitApple() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _formError = null;
      _activeAction = AuthAccountAction.apple;
    });

    final result = await ref.read(zeniAuthControllerProvider).signInWithApple();
    if (!mounted) return;

    setState(() {
      _activeAction = null;
      _formError = result.message;
    });

    if (result.isSuccess && result.user != null) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _submit(
    AuthAccountAction actionType,
    Future<ZeniAuthOperationResult> Function() action,
  ) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = email.isEmpty ? 'Informe seu e-mail.' : null;
      _passwordError = password.isEmpty ? 'Informe sua senha.' : null;
      _formError = null;
    });

    if (_emailError != null || _passwordError != null) return;

    setState(() {
      _activeAction = actionType;
    });

    final result = await action();
    if (!mounted) return;

    setState(() {
      _activeAction = null;
      _formError = result.message;
    });

    if (result.isSuccess && !result.requiresEmailConfirmation) {
      Navigator.of(context).pop(true);
    }
  }
}
