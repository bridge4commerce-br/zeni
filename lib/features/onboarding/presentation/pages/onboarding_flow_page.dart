import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/zeni_app_state_controller.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/zeni_avatar.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/feedback/zeni_error_popup.dart';
import '../../../../core/widgets/feedback/zeni_info_popup.dart';
import '../../../../core/widgets/feedback/zeni_success_popup.dart';
import '../../../../core/widgets/inputs/zeni_option_row.dart';
import '../../../../core/widgets/inputs/zeni_switch.dart';
import '../../../../core/widgets/inputs/zeni_text_input.dart';
import '../../../../core/widgets/layout/zeni_top_bar.dart';
import '../../../auth/presentation/widgets/parent_pin_dialog.dart';

class OnboardingFlowPage extends ConsumerStatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  ConsumerState<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends ConsumerState<OnboardingFlowPage> {
  static const _childEmojiOptions = ['🦊', '🐼', '🦁', '🐨'];
  static const _suggestedMissionTitle = 'Arrumar a cama';
  static const _suggestedRewardTitle = 'Escolher o filme';
  static const double _iconRotationDegrees = 6;
  static const double _iconScaleAmplitude = 0.08;
  static const Duration _iconAnimationDuration = Duration(milliseconds: 2400);

  final _childNameController = TextEditingController();
  final _missionTitleController = TextEditingController(
    text: _suggestedMissionTitle,
  );
  final _rewardTitleController = TextEditingController(
    text: _suggestedRewardTitle,
  );

  int _step = 0;
  String _selectedEmoji = _childEmojiOptions.first;
  String? _parentPin;
  bool _didSkipPin = false;
  bool _createSuggestedMission = true;
  bool _createSuggestedReward = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _childNameController.dispose();
    _missionTitleController.dispose();
    _rewardTitleController.dispose();
    super.dispose();
  }

  bool get _canFinish => _childNameController.text.trim().isNotEmpty;
  bool get _canContinueFromChildStep =>
      _childNameController.text.trim().isNotEmpty;

  Future<void> _showPinSkippedFeedback() {
    return ZeniInfoPopup.show(
      context,
      title: 'Tudo bem pular',
      message: 'Você pode criar o PIN depois na aba de ajustes.',
    );
  }

  void _goToStep(int step) {
    setState(() {
      _step = step;
    });
  }

  Future<void> _configurePin() async {
    final pin = await showDialog<String>(
      context: context,
      builder: (context) {
        return ParentPinDialog.create(hasExistingPin: _parentPin != null);
      },
    );
    if (!mounted || pin == null) return;

    setState(() {
      _parentPin = pin;
      _didSkipPin = false;
    });

    await ZeniSuccessPopup.show(
      context,
      title: 'PIN configurado',
      message: 'O modo responsável poderá usar esse PIN na entrada.',
    );

    if (!mounted) return;
    _goToStep(3);
  }

  Future<void> _finishOnboarding() async {
    if (!_canFinish || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final child = await ref
          .read(zeniAppStateControllerProvider.notifier)
          .completeInitialOnboardingSetup(
            childName: _childNameController.text.trim(),
            childEmoji: _selectedEmoji,
            hasCompletedOnboarding: true,
            parentPin: _parentPin,
            clearParentPin: _didSkipPin,
            createSuggestedMission: _createSuggestedMission,
            missionTitle: _missionTitleController.text,
            createSuggestedReward: _createSuggestedReward,
            rewardTitle: _rewardTitleController.text,
          );

      if (!mounted) return;

      await ZeniSuccessPopup.show(
        context,
        title: 'Tudo pronto!',
        message:
            '${child.name} já pode começar. As configurações iniciais foram salvas no app.',
      );
      if (!mounted) return;

      context.go('/');
    } catch (_) {
      if (!mounted) return;
      await ZeniErrorPopup.show(
        context,
        title: 'Não foi possível concluir',
        message: 'Tente novamente para finalizar a configuração inicial.',
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
            if (_step == 0) ...[
              Text('Bem-vindo ao Zeni', style: textTheme.displayLarge),
              const SizedBox(height: ZeniSpacing.sm),
              Text(
                'Organize missões, mimos e estrelas para transformar rotina em conquista.',
                style: textTheme.bodyLarge?.copyWith(
                  color: ZeniColors.mutedText,
                ),
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
                description:
                    'Defina recompensas claras para manter a motivação.',
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
              ZeniPrimaryButton(
                label: 'Começar configuração',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  setState(() {
                    _step = 1;
                  });
                },
              ),
            ] else if (_step == 1) ...[
              Text('Primeira configuração', style: textTheme.displayLarge),
              const SizedBox(height: ZeniSpacing.sm),
              Text(
                'Vamos criar a primeira criança e deixar o app pronto para uso.',
                style: textTheme.bodyLarge?.copyWith(
                  color: ZeniColors.mutedText,
                ),
              ),
              const SizedBox(height: ZeniSpacing.xl),
              ZeniCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primeira criança',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: ZeniSpacing.md),
                    Center(
                      child: ZeniAvatar(
                        label: _childNameController.text.trim().isEmpty
                            ? 'Primeira criança'
                            : _childNameController.text.trim(),
                        emoji: _selectedEmoji,
                        size: 84,
                      ),
                    ),
                    const SizedBox(height: ZeniSpacing.md),
                    Wrap(
                      spacing: ZeniSpacing.sm,
                      runSpacing: ZeniSpacing.sm,
                      children: [
                        for (final emoji in _childEmojiOptions)
                          ChoiceChip(
                            label: Text(
                              emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                            selected: _selectedEmoji == emoji,
                            onSelected: (_) {
                              setState(() {
                                _selectedEmoji = emoji;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: ZeniSpacing.lg),
                    ZeniTextInput(
                      controller: _childNameController,
                      label: 'Nome da criança',
                      hint: 'Ex.: Luna',
                      prefixIcon: Icons.child_care_rounded,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ZeniSpacing.lg),
              ZeniPrimaryButton(
                label: 'Continuar',
                icon: Icons.arrow_forward_rounded,
                onPressed: _canContinueFromChildStep && !_isSaving
                    ? () => _goToStep(2)
                    : null,
              ),
              const SizedBox(height: ZeniSpacing.md),
              ZeniSecondaryButton(
                label: 'Voltar',
                icon: Icons.arrow_back_rounded,
                onPressed: _isSaving ? null : () => _goToStep(0),
              ),
            ] else if (_step == 2) ...[
              Text('Proteção do responsável', style: textTheme.displayLarge),
              const SizedBox(height: ZeniSpacing.sm),
              Text(
                'Você pode proteger o modo responsável agora ou continuar sem PIN por enquanto.',
                style: textTheme.bodyLarge?.copyWith(
                  color: ZeniColors.mutedText,
                ),
              ),
              const SizedBox(height: ZeniSpacing.xl),
              ZeniCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ZeniOptionRow(
                      title: _parentPin == null
                          ? _didSkipPin
                                ? 'PIN será configurado depois'
                                : 'Configurar PIN agora'
                          : 'PIN configurado',
                      subtitle: _parentPin == null
                          ? _didSkipPin
                                ? 'Você escolheu concluir sem PIN neste momento.'
                                : 'Você pode proteger o modo responsável agora ou depois.'
                          : 'Toque para alterar o PIN de 4 dígitos.',
                      leading: const Icon(
                        Icons.pin_rounded,
                        color: ZeniColors.primaryDark,
                      ),
                      onTap: _configurePin,
                    ),
                    if (_parentPin == null) ...[
                      const SizedBox(height: ZeniSpacing.md),
                      ZeniSecondaryButton(
                        label: _didSkipPin
                            ? 'PIN pulado'
                            : 'Pular por enquanto',
                        icon: Icons.schedule_rounded,
                        onPressed: () async {
                          setState(() {
                            _parentPin = null;
                            _didSkipPin = true;
                          });

                          await _showPinSkippedFeedback();
                          if (!mounted) return;
                          _goToStep(3);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: ZeniSpacing.lg),
              ZeniPrimaryButton(
                label: _parentPin == null ? 'Continuar sem PIN' : 'Continuar',
                icon: Icons.arrow_forward_rounded,
                onPressed: _isSaving ? null : () => _goToStep(3),
              ),
              const SizedBox(height: ZeniSpacing.md),
              ZeniSecondaryButton(
                label: 'Voltar',
                icon: Icons.arrow_back_rounded,
                onPressed: _isSaving ? null : () => _goToStep(1),
              ),
            ] else if (_step == 3) ...[
              Text('Primeira missão', style: textTheme.displayLarge),
              const SizedBox(height: ZeniSpacing.sm),
              Text(
                'Comece com uma missão simples para a rotina de hoje.',
                style: textTheme.bodyLarge?.copyWith(
                  color: ZeniColors.mutedText,
                ),
              ),
              const SizedBox(height: ZeniSpacing.xl),
              ZeniCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ZeniSwitch(
                      title: 'Usar missão sugerida',
                      subtitle:
                          'Criar uma missão inicial simples para começar.',
                      icon: Icons.check_circle_outline_rounded,
                      value: _createSuggestedMission,
                      onChanged: (value) {
                        setState(() {
                          _createSuggestedMission = value;
                        });
                      },
                    ),
                    if (_createSuggestedMission) ...[
                      const SizedBox(height: ZeniSpacing.md),
                      ZeniTextInput(
                        controller: _missionTitleController,
                        label: 'Nome da missão',
                        hint: _suggestedMissionTitle,
                        prefixIcon: Icons.task_alt_rounded,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: ZeniSpacing.lg),
              ZeniPrimaryButton(
                label: 'Continuar',
                icon: Icons.arrow_forward_rounded,
                onPressed: _isSaving ? null : () => _goToStep(4),
              ),
              const SizedBox(height: ZeniSpacing.md),
              ZeniSecondaryButton(
                label: 'Voltar',
                icon: Icons.arrow_back_rounded,
                onPressed: _isSaving ? null : () => _goToStep(2),
              ),
            ] else ...[
              Text('Primeiro mimo', style: textTheme.displayLarge),
              const SizedBox(height: ZeniSpacing.sm),
              Text(
                'Defina um primeiro mimo ou deixe para configurar depois.',
                style: textTheme.bodyLarge?.copyWith(
                  color: ZeniColors.mutedText,
                ),
              ),
              const SizedBox(height: ZeniSpacing.xl),
              ZeniCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primeiro mimo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: ZeniSpacing.md),
                    ZeniSwitch(
                      title: 'Usar mimo sugerido',
                      subtitle:
                          'Você também pode deixar para configurar depois.',
                      icon: Icons.card_giftcard_rounded,
                      value: _createSuggestedReward,
                      onChanged: (value) {
                        setState(() {
                          _createSuggestedReward = value;
                        });
                      },
                    ),
                    if (_createSuggestedReward) ...[
                      const SizedBox(height: ZeniSpacing.md),
                      ZeniTextInput(
                        controller: _rewardTitleController,
                        label: 'Nome do mimo',
                        hint: _suggestedRewardTitle,
                        prefixIcon: Icons.redeem_rounded,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: ZeniSpacing.lg),
              ZeniPrimaryButton(
                label: _isSaving ? 'Finalizando...' : 'Concluir configuração',
                icon: Icons.check_circle_rounded,
                onPressed: _canFinish && !_isSaving ? _finishOnboarding : null,
              ),
              const SizedBox(height: ZeniSpacing.md),
              ZeniSecondaryButton(
                label: 'Voltar',
                icon: Icons.arrow_back_rounded,
                onPressed: _isSaving
                    ? null
                    : () => _goToStep(3),
              ),
            ],
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
                  child: Text(widget.emoji, style: const TextStyle(fontSize: 32)),
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
