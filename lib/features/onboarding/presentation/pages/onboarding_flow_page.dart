import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/feedback/zeni_error_popup.dart';
import '../../../../core/widgets/layout/zeni_top_bar.dart';

class OnboardingFlowPage extends ConsumerStatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  ConsumerState<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends ConsumerState<OnboardingFlowPage> {
  static const double _iconRotationDegrees = 6;
  static const double _iconScaleAmplitude = 0.08;
  static const Duration _iconAnimationDuration = Duration(milliseconds: 2400);

  bool _isSaving = false;

  Future<void> _finishOnboarding() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(zeniAppStateControllerProvider.notifier)
          .completeInstitutionalOnboarding();

      if (!mounted) return;

      context.go('/');
    } catch (_) {
      if (!mounted) return;
      await ZeniErrorPopup.show(
        context,
        title: 'Não foi possível concluir',
        message: 'Tente novamente para concluir a apresentação inicial.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ZeniScaffold(
      appBar: const ZeniTopBar(
        title: 'Zeni',
        subtitle: 'Hábitos que viram conquistas',
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ZeniSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bem-vindo ao Zeni', style: textTheme.displayLarge),
            const SizedBox(height: ZeniSpacing.sm),
            Text(
              'Organize missões, mimos e estrelas para transformar rotina em conquista.',
              style: textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
            ),
            const SizedBox(height: ZeniSpacing.xl),
            const _OnboardingHighlightCard(
              emoji: '✅',
              title: 'Missões',
              description: 'Combine tarefas simples e acompanhe o progresso.',
              phaseOffset: 0,
            ),
            const SizedBox(height: ZeniSpacing.md),
            const _OnboardingHighlightCard(
              emoji: '🎁',
              title: 'Mimos',
              description: 'Defina recompensas claras para manter a motivação.',
              phaseOffset: 0.8,
            ),
            const SizedBox(height: ZeniSpacing.md),
            const _OnboardingHighlightCard(
              emoji: '⭐',
              title: 'Estrelas',
              description: 'Veja saldo, histórico e potencial do mês.',
              phaseOffset: 1.6,
            ),
            const SizedBox(height: ZeniSpacing.xl),
            ZeniCard(
              child: Text(
                'Esta etapa apresenta o app. A criação da criança, do PIN, da primeira missão e do primeiro mimo acontece só quando você escolher começar uma nova família.',
                style: textTheme.bodyMedium?.copyWith(
                  color: ZeniColors.mutedText,
                ),
              ),
            ),
            const SizedBox(height: ZeniSpacing.xl),
            ZeniPrimaryButton(
              label: _isSaving ? 'Continuando...' : 'Continuar',
              icon: Icons.arrow_forward_rounded,
              onPressed: _isSaving ? null : _finishOnboarding,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingHighlightCard extends StatefulWidget {
  const _OnboardingHighlightCard({
    required this.emoji,
    required this.title,
    required this.description,
    this.phaseOffset = 0,
  });

  final String emoji;
  final String title;
  final String description;
  final double phaseOffset;

  @override
  State<_OnboardingHighlightCard> createState() =>
      _OnboardingHighlightCardState();
}

class _OnboardingHighlightCardState extends State<_OnboardingHighlightCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _motion;
  late final bool _shouldAnimate;

  @override
  void initState() {
    super.initState();
    _shouldAnimate = !Platform.environment.containsKey('FLUTTER_TEST');
    _controller = AnimationController(
      vsync: this,
      duration: _OnboardingFlowPageState._iconAnimationDuration,
    );
    _motion = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (_shouldAnimate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.2;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final motionValue = _motion.value;
        final value = (motionValue * 2 * pi) + widget.phaseOffset;
        final rotation =
            (_OnboardingFlowPageState._iconRotationDegrees * pi / 180) *
            sin(value);
        final scale =
            1 + (_OnboardingFlowPageState._iconScaleAmplitude * motionValue);

        return ZeniCard(
          child: Row(
            children: [
              Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: scale,
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: ZeniSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: ZeniSpacing.xs),
                    Text(
                      widget.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ZeniColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
