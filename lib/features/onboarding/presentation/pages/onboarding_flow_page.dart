import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/zeni_responsive.dart';
import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_radius.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_brand_logo.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/feedback/zeni_error_popup.dart';
import '../../../../core/widgets/zeni_mascot.dart';

class OnboardingFlowPage extends ConsumerStatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  ConsumerState<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends ConsumerState<OnboardingFlowPage>
    with TickerProviderStateMixin {
  static const Duration _entranceDuration = Duration(milliseconds: 1400);

  late final AnimationController _entranceController;
  late final AnimationController _starAmbientController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _starAmbientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _entranceController =
        AnimationController(vsync: this, duration: _entranceDuration)
          ..forward().whenComplete(() {
            if (!Platform.environment.containsKey('FLUTTER_TEST')) {
              _starAmbientController.repeat();
            }
          });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _starAmbientController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await ref
          .read(zeniAppStateControllerProvider.notifier)
          .completeInstitutionalOnboarding();
      if (mounted) context.go('/');
    } catch (_) {
      if (!mounted) return;
      await ZeniErrorPopup.show(
        context,
        title: 'Não foi possível concluir',
        message: 'Tente novamente para concluir a apresentação inicial.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && _entranceController.value != 1) {
      _entranceController.value = 1;
    }
    if (reduceMotion && _starAmbientController.isAnimating) {
      _starAmbientController.stop();
    }

    return ZeniScaffold(
      child: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _entranceController,
            _starAmbientController,
          ]),
          builder: (context, _) => _OnboardingV2Content(
            progress: reduceMotion ? 1 : _entranceController.value,
            starAmbientProgress: reduceMotion
                ? 0
                : _starAmbientController.value,
            reduceMotion: reduceMotion,
            isSaving: _isSaving,
            onStart: _isSaving ? null : _finishOnboarding,
          ),
        ),
      ),
    );
  }
}

class _OnboardingV2Content extends StatelessWidget {
  const _OnboardingV2Content({
    required this.progress,
    required this.starAmbientProgress,
    required this.reduceMotion,
    required this.isSaving,
    required this.onStart,
  });

  final double progress;
  final double starAmbientProgress;
  final bool reduceMotion;
  final bool isSaving;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final content = Curves.easeOutCubic.transform(_interval(0.45, 1));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: ZeniPageFrame(
        width: ZeniPageWidth.focus,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height - 80,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _OnboardingHero(
                progress: progress,
                ambientProgress: starAmbientProgress,
                reduceMotion: reduceMotion,
              ),
              const SizedBox(height: ZeniSpacing.xl),
              Opacity(
                opacity: content,
                child: Column(
                  children: [
                    Text(
                      'Pequenas atitudes. Grandes conquistas.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: ZeniSpacing.md),
                    Text(
                      'Missões simples, estrelas e mimos para ajudar sua família a construir autonomia no dia a dia.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: ZeniSpacing.xl),
                    const _ConceptRow(),
                    const SizedBox(height: ZeniSpacing.xxl),
                    ZeniPrimaryButton(
                      label: isSaving ? 'Começando...' : 'Começar',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: onStart,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _interval(double begin, double end) =>
      ((progress - begin) / (end - begin)).clamp(0, 1);
}

class _ConceptRow extends StatelessWidget {
  const _ConceptRow();

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: ZeniSpacing.sm,
    runSpacing: ZeniSpacing.sm,
    children: const [
      _ConceptChip(icon: Icons.check_circle_rounded, label: 'Missões'),
      _ConceptChip(icon: Icons.star_rounded, label: 'Estrelas'),
      _ConceptChip(icon: Icons.card_giftcard_rounded, label: 'Mimos'),
    ],
  );
}

class _ConceptChip extends StatelessWidget {
  const _ConceptChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Chip(
      avatar: Icon(icon, size: 18, color: ZeniColors.primaryDark),
      label: Text(label),
      side: BorderSide(color: ZeniColors.primary.withValues(alpha: 0.28)),
      backgroundColor: ZeniColors.primaryLight.withValues(alpha: 0.22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ZeniRadius.pill),
      ),
    ),
  );
}

class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero({
    required this.progress,
    required this.ambientProgress,
    required this.reduceMotion,
  });

  final double progress;
  final double ambientProgress;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final mascotProgress = Curves.easeOutBack.transform(_interval(0, 0.48));
    final mascotOpacity = mascotProgress.clamp(0.0, 1.0);
    final symbolProgress = Curves.easeInOutCubic.transform(
      _interval(0.42, 0.9),
    );
    final symbolScale = _symbolScale(symbolProgress);
    final pathArc = 12 * (1 - ((symbolProgress * 2) - 1).abs());
    final medalGlow = Curves.easeOut.transform(_interval(0.36, 0.52));
    final ambient = reduceMotion ? 0.0 : ambientProgress;

    return SizedBox(
      width: 240,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            child: Opacity(
              opacity: mascotOpacity,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - mascotProgress)),
                child: Transform.scale(
                  scale: 0.85 + (0.15 * mascotProgress),
                  child: const ZeniMascot(
                    state: ZeniMascotState.idle,
                    size: 196,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 82,
            child: _StarDecoration(
              key: const Key('onboarding-star-left'),
              opacity: _interval(0.5, 0.72),
              size: 22,
              ambientProgress: ambient,
              phase: 0,
            ),
          ),
          Positioned(
            right: 16,
            top: 119,
            child: _StarDecoration(
              key: const Key('onboarding-star-right'),
              opacity: _interval(0.62, 0.82),
              size: 18,
              ambientProgress: ambient,
              phase: 0.5,
            ),
          ),
          Positioned(
            left: 108,
            top: 146,
            child: Opacity(
              opacity: (1 - medalGlow).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.7 + medalGlow,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: ZeniColors.accent.withValues(alpha: 0.42),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ZeniColors.accent.withValues(alpha: 0.42),
                        blurRadius: 14,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -18 + (124 * (1 - symbolProgress)) - pathArc,
            child: Transform.translate(
              offset: Offset(pathArc * 0.7, 0),
              child: Transform.rotate(
                angle: (1 - symbolProgress) * 3.6,
                child: Transform.scale(
                  scale: symbolScale,
                  child: Opacity(
                    opacity: symbolProgress.clamp(0.0, 1.0),
                    child: const ZeniBrandLogo(width: 78),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _interval(double begin, double end) =>
      ((progress - begin) / (end - begin)).clamp(0, 1);

  double _symbolScale(double value) {
    if (value < 0.82) return 0.3 + (0.7 * (value / 0.82));
    return 1.08 - (0.08 * ((value - 0.82) / 0.18));
  }
}

class _StarDecoration extends StatelessWidget {
  const _StarDecoration({
    super.key,
    required this.opacity,
    required this.size,
    required this.ambientProgress,
    required this.phase,
  });

  final double opacity;
  final double size;
  final double ambientProgress;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final wave = (ambientProgress + phase) % 1;
    final curve = Curves.easeInOut.transform(
      wave <= 0.5 ? wave * 2 : (1 - wave) * 2,
    );
    final delta = (curve - 0.5) * 2;
    return Transform.translate(
      offset: Offset(0, -4 * delta),
      child: Transform.scale(
        scale: 1 + (0.04 * delta),
        child: Opacity(
          opacity: opacity,
          child: Text('⭐', style: TextStyle(fontSize: size)),
        ),
      ),
    );
  }
}
