import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/zeni_supabase.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/inputs/zeni_text_input.dart';
import '../../../../core/widgets/layout/zeni_modal_sheet_container.dart';
import '../../data/repositories/zeni_auth_repository.dart';
import '../providers/zeni_account_providers.dart';
import '../providers/zeni_auth_providers.dart';
import 'auth_provider_button.dart';
import 'clear_local_device_data_sheet.dart';

enum AuthAccountAction { emailSignIn, emailSignUp, google, apple }

enum AuthEmailAction { signIn, signUp }

class AuthAccountSheet extends ConsumerStatefulWidget {
  const AuthAccountSheet({
    super.key,
    required this.isSupabaseConfigured,
    required this.bootstrapState,
    this.preferredEmailAction = AuthEmailAction.signIn,
    this.showDragHandle = true,
  });

  final bool isSupabaseConfigured;
  final ZeniSupabaseBootstrapState bootstrapState;
  final AuthEmailAction preferredEmailAction;
  final bool showDragHandle;

  @override
  ConsumerState<AuthAccountSheet> createState() => _AuthAccountSheetState();
}

class _AuthAccountSheetState extends ConsumerState<AuthAccountSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  AuthAccountAction? _activeAction;
  AuthEmailAction? _emailAction;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _formErrorTitle;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final hasAuthenticatedSession =
        authState.isAuthenticated &&
        ref.watch(authRepositoryProvider).currentUser != null;
    final accountProfile = ref
        .watch(currentAccountProfileProvider)
        .asData
        ?.value;
    final isGoogleAvailable = ref.watch(googleSignInAvailableProvider);
    final isAppleAvailable = ref.watch(appleSignInAvailableProvider);
    final isBusy = _activeAction != null;
    final user = authState.user;
    final profileName = accountProfile?.displayName.trim() ?? '';
    final providerName = user?.displayName?.trim() ?? '';
    final displayName = profileName.isNotEmpty
        ? profileName
        : providerName.isNotEmpty
        ? providerName
        : 'Responsável';

    return ZeniModalSheetContainer(
      title: 'Conta da família',
      showDragHandle: widget.showDragHandle,
      child: SingleChildScrollView(
        child:
            hasAuthenticatedSession &&
                authState.isFamilyIdentityBlocked &&
                user != null
            ? _AuthenticatedFamilyBlockedView(
                displayName: displayName,
                email: user.email ?? accountProfile?.email,
                isBusy: isBusy,
                onSignOut: _confirmAndSignOut,
                onClearLocalData: _clearLocalDataAndContinue,
              )
            : _emailAction == null
            ? _ProviderOptions(
                isBusy: isBusy,
                isAppleAvailable: isAppleAvailable,
                activeAction: _activeAction,
                onGoogle: () => _submitGoogle(isGoogleAvailable),
                onApple: _submitApple,
                onEmail: () => setState(() {
                  _emailAction = widget.preferredEmailAction;
                  _formErrorTitle = null;
                  _formError = null;
                }),
                formErrorTitle: _formErrorTitle,
                formError: _formError,
              )
            : _EmailForm(
                emailAction: _emailAction!,
                isBusy: isBusy,
                nameController: _nameController,
                emailController: _emailController,
                passwordController: _passwordController,
                nameError: _nameError,
                emailError: _emailError,
                passwordError: _passwordError,
                formErrorTitle: _formErrorTitle,
                formError: _formError,
                onBack: isBusy
                    ? null
                    : () => setState(() {
                        _emailAction = null;
                        _nameError = null;
                        _emailError = null;
                        _passwordError = null;
                        _formErrorTitle = null;
                        _formError = null;
                      }),
                onSubmit: _emailAction == AuthEmailAction.signUp
                    ? _submitSignUp
                    : _submitSignIn,
                onSwitchAction: isBusy
                    ? null
                    : () => setState(() {
                        _emailAction = _emailAction == AuthEmailAction.signUp
                            ? AuthEmailAction.signIn
                            : AuthEmailAction.signUp;
                        _nameError = null;
                        _emailError = null;
                        _passwordError = null;
                        _formErrorTitle = null;
                        _formError = null;
                      }),
              ),
      ),
    );
  }

  Future<void> _submitSignUp() => _submit(
    AuthAccountAction.emailSignUp,
    () => ref
        .read(zeniAuthControllerProvider)
        .signUpWithEmailPassword(
          displayName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
  );

  Future<void> _submitSignIn() => _submit(
    AuthAccountAction.emailSignIn,
    () => ref
        .read(zeniAuthControllerProvider)
        .signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
  );

  Future<void> _submitGoogle(bool isGoogleAvailable) async {
    setState(() {
      _formErrorTitle = null;
      _formError = null;
      _activeAction = AuthAccountAction.google;
    });
    final result = await ref
        .read(zeniAuthControllerProvider)
        .signInWithGoogle();
    if (!mounted) return;
    setState(() {
      _activeAction = null;
      _applyOperationFeedback(result, isGoogleAvailable: isGoogleAvailable);
    });
    if (result.isSuccess && result.user != null) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _submitApple() async {
    setState(() {
      _formErrorTitle = null;
      _formError = null;
      _activeAction = AuthAccountAction.apple;
    });
    final result = await ref.read(zeniAuthControllerProvider).signInWithApple();
    if (!mounted) return;
    setState(() {
      _activeAction = null;
      _applyOperationFeedback(result);
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
    final isSignUp = actionType == AuthAccountAction.emailSignUp;
    setState(() {
      _nameError = isSignUp && _nameController.text.trim().isEmpty
          ? 'Informe seu nome.'
          : null;
      _emailError = email.isEmpty ? 'Informe seu e-mail.' : null;
      _passwordError = password.isEmpty ? 'Informe sua senha.' : null;
      _formErrorTitle = null;
      _formError = null;
    });
    if (_nameError != null || _emailError != null || _passwordError != null) {
      return;
    }
    setState(() => _activeAction = actionType);
    final result = await action();
    if (!mounted) return;
    setState(() {
      _activeAction = null;
      _applyOperationFeedback(result);
    });
    if (result.isSuccess && !result.requiresEmailConfirmation) {
      Navigator.of(context).pop(true);
    }
  }

  void _applyOperationFeedback(
    ZeniAuthOperationResult result, {
    bool isGoogleAvailable = true,
  }) {
    if (result.isSuccess) {
      _formErrorTitle = null;
      _formError = null;
      return;
    }
    if (result.issue == ZeniAuthIssue.localFamilyConflict) {
      _formErrorTitle = localFamilyConflictTitle;
      _formError = localFamilyConflictMessage;
      return;
    }
    _formErrorTitle = null;
    _formError = _friendlyAuthError(
      result.message,
      isGoogleAvailable: isGoogleAvailable,
    );
  }

  String _friendlyAuthError(String? message, {bool isGoogleAvailable = true}) {
    if (message?.toLowerCase().contains('cancel') ?? false) {
      return 'A entrada foi cancelada.';
    }
    if (!isGoogleAvailable) {
      return 'Não foi possível continuar com Google neste momento. Tente outro método.';
    }
    return 'Não foi possível continuar agora. Tente novamente ou escolha outro método.';
  }

  Future<void> _confirmAndSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Os dados desta família continuarão disponíveis neste aparelho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _activeAction = AuthAccountAction.emailSignIn);
    final result = await ref.read(zeniAuthControllerProvider).signOut();
    if (!mounted) return;
    setState(() {
      _activeAction = null;
      _emailAction = null;
      _applyOperationFeedback(result);
    });
  }

  Future<void> _clearLocalDataAndContinue() async {
    final didClear = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ClearLocalDeviceDataSheet(
          onConfirm: () async {
            await ref
                .read(zeniAppStateControllerProvider.notifier)
                .clearLocalDeviceData();
            final result = await ref
                .read(zeniAuthControllerProvider)
                .prepareCurrentSession();
            if (!result.isSuccess) {
              throw StateError(
                result.message ?? 'Não foi possível preparar esta família.',
              );
            }
          },
        ),
      ),
    );
    if (mounted && didClear == true) Navigator.of(context).pop(true);
  }
}

class _AuthenticatedFamilyBlockedView extends StatelessWidget {
  const _AuthenticatedFamilyBlockedView({
    required this.displayName,
    required this.email,
    required this.isBusy,
    required this.onSignOut,
    required this.onClearLocalData,
  });

  final String displayName;
  final String? email;
  final bool isBusy;
  final VoidCallback onSignOut;
  final VoidCallback onClearLocalData;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.account_circle_outlined),
          const SizedBox(width: ZeniSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (email != null)
                  Text(
                    email!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ZeniColors.mutedText,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            'Conectado',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: ZeniColors.mutedText),
          ),
        ],
      ),
      const SizedBox(height: ZeniSpacing.xl),
      Text(
        localFamilyConflictTitle,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: ZeniSpacing.xs),
      Text(
        localFamilyConflictMessage,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: ZeniSpacing.xl),
      ZeniSecondaryButton(
        label: isBusy ? 'Saindo...' : 'Sair da conta',
        icon: Icons.logout_rounded,
        onPressed: isBusy ? null : onSignOut,
      ),
      const SizedBox(height: ZeniSpacing.sm),
      ZeniSecondaryButton(
        key: const Key('legacy-clear-local-data-button'),
        label: 'Apagar dados deste aparelho e entrar com esta conta',
        icon: Icons.delete_forever_rounded,
        onPressed: isBusy ? null : onClearLocalData,
      ),
    ],
  );
}

class _ProviderOptions extends StatelessWidget {
  const _ProviderOptions({
    required this.isBusy,
    required this.isAppleAvailable,
    required this.activeAction,
    required this.onGoogle,
    required this.onApple,
    required this.onEmail,
    required this.formErrorTitle,
    required this.formError,
  });
  final bool isBusy;
  final bool isAppleAvailable;
  final AuthAccountAction? activeAction;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onEmail;
  final String? formErrorTitle;
  final String? formError;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Escolha como deseja continuar.',
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
      ),
      const SizedBox(height: ZeniSpacing.xl),
      AuthProviderButton.google(
        key: const Key('auth-google-button'),
        label: activeAction == AuthAccountAction.google
            ? 'Conectando com Google...'
            : 'Continuar com Google',
        onPressed: isBusy ? null : onGoogle,
      ),
      if (isAppleAvailable) ...[
        const SizedBox(height: ZeniSpacing.md),
        AuthProviderButton.apple(
          key: const Key('auth-apple-button'),
          label: activeAction == AuthAccountAction.apple
              ? 'Conectando com Apple...'
              : 'Continuar com Apple',
          onPressed: isBusy ? null : onApple,
        ),
      ],
      const SizedBox(height: ZeniSpacing.md),
      ZeniSecondaryButton(
        key: const Key('auth-email-button'),
        label: 'Continuar com e-mail',
        icon: Icons.email_outlined,
        onPressed: isBusy ? null : onEmail,
      ),
      if (formError != null) ...[
        const SizedBox(height: ZeniSpacing.md),
        if (formErrorTitle != null) ...[
          Text(formErrorTitle!, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: ZeniSpacing.xs),
        ],
        Text(
          formError!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    ],
  );
}

class _EmailForm extends StatelessWidget {
  const _EmailForm({
    required this.emailAction,
    required this.isBusy,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.nameError,
    required this.emailError,
    required this.passwordError,
    required this.formErrorTitle,
    required this.formError,
    required this.onBack,
    required this.onSubmit,
    required this.onSwitchAction,
  });
  final AuthEmailAction emailAction;
  final bool isBusy;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? formErrorTitle;
  final String? formError;
  final VoidCallback? onBack;
  final VoidCallback onSubmit;
  final VoidCallback? onSwitchAction;

  @override
  Widget build(BuildContext context) {
    final isSignUp = emailAction == AuthEmailAction.signUp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Outras opções'),
        ),
        const SizedBox(height: ZeniSpacing.sm),
        Text(
          isSignUp ? 'Crie sua conta com e-mail' : 'Entre com seu e-mail',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: ZeniSpacing.lg),
        if (isSignUp) ...[
          ZeniTextInput(
            key: const Key('auth-name-input'),
            controller: nameController,
            label: 'Seu nome',
            hint: 'Como você quer ser chamado',
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            errorText: nameError,
          ),
          const SizedBox(height: ZeniSpacing.md),
        ],
        ZeniTextInput(
          key: const Key('auth-email-input'),
          controller: emailController,
          label: 'E-mail',
          hint: 'responsavel@email.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.none,
          errorText: emailError,
        ),
        const SizedBox(height: ZeniSpacing.md),
        ZeniTextInput(
          key: const Key('auth-password-input'),
          controller: passwordController,
          label: 'Senha',
          hint: 'Use pelo menos 6 caracteres',
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.none,
          obscureText: true,
          errorText: passwordError,
        ),
        if (formError != null) ...[
          const SizedBox(height: ZeniSpacing.md),
          if (formErrorTitle != null) ...[
            Text(
              formErrorTitle!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: ZeniSpacing.xs),
          ],
          Text(
            formError!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: ZeniSpacing.xl),
        ZeniPrimaryButton(
          label: isBusy
              ? (isSignUp ? 'Criando conta...' : 'Entrando...')
              : (isSignUp ? 'Criar conta' : 'Entrar'),
          onPressed: isBusy ? null : onSubmit,
        ),
        const SizedBox(height: ZeniSpacing.sm),
        Center(
          child: TextButton(
            onPressed: onSwitchAction,
            child: Text(isSignUp ? 'Já tenho uma conta' : 'Criar uma conta'),
          ),
        ),
      ],
    );
  }
}
