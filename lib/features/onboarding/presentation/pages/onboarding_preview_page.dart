import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/accessibility/zeni_accessibility_controller.dart';
import '../../../../core/accessibility/zeni_accessibility_settings.dart';
import '../../../../core/theme/zeni_colors.dart';
import '../../../../core/theme/zeni_spacing.dart';
import '../../../../core/widgets/base/status_badge.dart';
import '../../../../core/widgets/base/zeni_avatar.dart';
import '../../../../core/widgets/base/zeni_balance_pill.dart';
import '../../../../core/widgets/base/zeni_card.dart';
import '../../../../core/widgets/base/zeni_fab.dart';
import '../../../../core/widgets/base/zeni_icon_action_button.dart';
import '../../../../core/widgets/base/zeni_primary_button.dart';
import '../../../../core/widgets/base/zeni_scaffold.dart';
import '../../../../core/widgets/base/zeni_secondary_button.dart';
import '../../../../core/widgets/feedback/danger_action_text.dart';
import '../../../../core/widgets/feedback/zeni_error_popup.dart';
import '../../../../core/widgets/feedback/zeni_info_popup.dart';
import '../../../../core/widgets/feedback/zeni_success_popup.dart';
import '../../../../core/widgets/inputs/counter_stepper.dart';
import '../../../../core/widgets/inputs/zeni_multiline_input.dart';
import '../../../../core/widgets/inputs/zeni_option_row.dart';
import '../../../../core/widgets/inputs/zeni_switch.dart';
import '../../../../core/widgets/inputs/zeni_text_input.dart';
import '../../../../core/widgets/layout/zeni_top_bar.dart';

class OnboardingPreviewPage extends ConsumerStatefulWidget {
  const OnboardingPreviewPage({super.key});

  @override
  ConsumerState<OnboardingPreviewPage> createState() =>
      _OnboardingPreviewPageState();
}

class _OnboardingPreviewPageState extends ConsumerState<OnboardingPreviewPage> {
  final _nameController = TextEditingController(text: 'Luna');
  final _missionController = TextEditingController(
    text: 'Arrumar a cama antes da escola',
  );

  int _stars = 10;
  String _selectedProfile = 'child';

  @override
  void dispose() {
    _nameController.dispose();
    _missionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = ref.watch(zeniAccessibilityControllerProvider);
    final settings = accessibility.settings;
    final textTheme = Theme.of(context).textTheme;

    return ZeniScaffold(
      appBar: ZeniTopBar(
        title: 'ZeniKids',
        subtitle: 'Hábitos que viram conquistas',
        actions: [
          ZeniIconActionButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Ver notificações',
            tone: ZeniIconActionTone.primary,
            onPressed: () {
              ZeniInfoPopup.show(
                context,
                title: 'Notificações',
                message: 'Aqui entrarão lembretes de missões e mimos.',
              );
            },
          ),
          const SizedBox(width: ZeniSpacing.sm),
        ],
      ),
      floatingActionButton: ZeniFab(
        icon: Icons.add_rounded,
        label: 'Missão',
        tooltip: 'Criar missão',
        onPressed: () {
          ZeniSuccessPopup.show(
            context,
            title: 'Ação rápida',
            message: 'Depois esse botão abrirá a criação de missão.',
          );
        },
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ZeniSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                ZeniAvatar(label: 'Perfil da criança', emoji: '🦊', size: 72),
                SizedBox(width: ZeniSpacing.md),
                ZeniBalancePill(stars: 120),
              ],
            ),
            const SizedBox(height: ZeniSpacing.xl),
            Text('Componentes base Zeni', style: textTheme.displayLarge),
            const SizedBox(height: ZeniSpacing.sm),
            Text(
              'Validando tema, fonte para dislexia, escala de texto, inputs e feedbacks.',
              style: textTheme.bodyLarge?.copyWith(color: ZeniColors.mutedText),
            ),
            const SizedBox(height: ZeniSpacing.xl),
            ZeniCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Acessibilidade', style: textTheme.titleLarge),
                  const SizedBox(height: ZeniSpacing.md),
                  ZeniSwitch(
                    title: 'Fonte para dislexia',
                    subtitle: 'Usar OpenDyslexic nos textos do app',
                    icon: Icons.text_fields_rounded,
                    value: settings.dyslexiaFontEnabled,
                    onChanged: accessibility.setDyslexiaFontEnabled,
                  ),
                  ZeniSwitch(
                    title: 'Leitura em voz alta',
                    subtitle: 'Preparar TTS do dispositivo',
                    icon: Icons.record_voice_over_rounded,
                    value: settings.ttsEnabled,
                    onChanged: accessibility.setTtsEnabled,
                  ),
                  ZeniSwitch(
                    title: 'Leitura por perfil da criança',
                    subtitle: 'Permitir configuração individual por criança',
                    icon: Icons.child_care_rounded,
                    value: settings.readAloudByChildProfile,
                    onChanged: accessibility.setReadAloudByChildProfile,
                  ),
                  const SizedBox(height: ZeniSpacing.md),
                  CounterStepper(
                    label: 'Tamanho da letra',
                    subtitle: 'Ajuste visual aplicado no app inteiro',
                    value: (settings.textScale * 100).round(),
                    min: 85,
                    max: 135,
                    step: 5,
                    suffix: '%',
                    onChanged: (value) {
                      accessibility.setTextScale(value / 100);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: ZeniSpacing.lg),
            ZeniCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tema do app', style: textTheme.titleLarge),
                  const SizedBox(height: ZeniSpacing.md),
                  for (final option in ZeniThemeModeOption.values) ...[
                    ZeniOptionRow(
                      title: option.label,
                      subtitle: option.description,
                      selected: settings.themeModeOption == option,
                      leading: Icon(switch (option) {
                        ZeniThemeModeOption.system =>
                          Icons.phone_iphone_rounded,
                        ZeniThemeModeOption.light => Icons.light_mode_rounded,
                        ZeniThemeModeOption.dark => Icons.dark_mode_rounded,
                      }, color: ZeniColors.primaryDark),
                      onTap: () {
                        accessibility.setThemeModeOption(option);
                      },
                    ),
                    if (option != ZeniThemeModeOption.values.last)
                      const SizedBox(height: ZeniSpacing.sm),
                  ],
                ],
              ),
            ),
            const SizedBox(height: ZeniSpacing.xl),
            ZeniCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Wrap(
                    spacing: ZeniSpacing.sm,
                    runSpacing: ZeniSpacing.sm,
                    children: [
                      StatusBadge(
                        label: 'Concluída',
                        icon: Icons.check_rounded,
                        tone: StatusBadgeTone.success,
                      ),
                      StatusBadge(
                        label: 'Pendente',
                        icon: Icons.schedule_rounded,
                        tone: StatusBadgeTone.warning,
                      ),
                      StatusBadge(
                        label: 'Aprovada',
                        icon: Icons.verified_rounded,
                        tone: StatusBadgeTone.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: ZeniSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Missão exemplo',
                          style: textTheme.titleLarge,
                        ),
                      ),
                      ZeniIconActionButton(
                        icon: Icons.edit_rounded,
                        tooltip: 'Editar missão',
                        tone: ZeniIconActionTone.primary,
                        onPressed: () {
                          ZeniInfoPopup.show(
                            context,
                            title: 'Editar missão',
                            message:
                                'A edição será criada no fluxo de missões.',
                          );
                        },
                      ),
                      const SizedBox(width: ZeniSpacing.sm),
                      ZeniIconActionButton(
                        icon: Icons.delete_outline_rounded,
                        tooltip: 'Excluir missão',
                        tone: ZeniIconActionTone.danger,
                        onPressed: () {
                          ZeniErrorPopup.show(
                            context,
                            title: 'Ação perigosa',
                            message:
                                'Depois vamos confirmar exclusões com cuidado.',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: ZeniSpacing.xl),
            ZeniTextInput(
              controller: _nameController,
              label: 'Nome da criança',
              hint: 'Ex.: Luna',
              prefixIcon: Icons.child_care_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: ZeniSpacing.lg),
            ZeniMultilineInput(
              controller: _missionController,
              label: 'Descrição da missão',
              hint: 'Explique a missão de forma simples',
              maxLength: 120,
            ),
            const SizedBox(height: ZeniSpacing.lg),
            CounterStepper(
              label: 'Valor da missão',
              subtitle: 'Quantidade de estrelas ao concluir',
              value: _stars,
              min: 1,
              max: 100,
              step: 5,
              suffix: '⭐',
              onChanged: (value) {
                setState(() {
                  _stars = value;
                });
              },
            ),
            const SizedBox(height: ZeniSpacing.lg),
            ZeniOptionRow(
              title: 'Modo criança',
              subtitle: 'Ver missões, saldo e mimos disponíveis',
              selected: _selectedProfile == 'child',
              leading: const Icon(
                Icons.star_rounded,
                color: ZeniColors.primary,
              ),
              onTap: () {
                setState(() {
                  _selectedProfile = 'child';
                });
              },
            ),
            const SizedBox(height: ZeniSpacing.md),
            ZeniOptionRow(
              title: 'Modo responsável',
              subtitle: 'Gerenciar família, missões e recompensas',
              selected: _selectedProfile == 'parent',
              leading: const Icon(
                Icons.family_restroom_rounded,
                color: ZeniColors.primaryDark,
              ),
              onTap: () {
                setState(() {
                  _selectedProfile = 'parent';
                });
              },
            ),
            const SizedBox(height: ZeniSpacing.xl),
            ZeniPrimaryButton(
              label: 'Testar sucesso',
              icon: Icons.check_circle_rounded,
              onPressed: () {
                ZeniSuccessPopup.show(
                  context,
                  title: 'Missão configurada!',
                  message: 'A missão vale $_stars estrelas.',
                );
              },
            ),
            const SizedBox(height: ZeniSpacing.md),
            ZeniSecondaryButton(
              label: 'Testar informação',
              icon: Icons.info_rounded,
              onPressed: () {
                ZeniInfoPopup.show(
                  context,
                  title: 'Dica Zeni',
                  message: 'Esses componentes serão usados nos formulários.',
                );
              },
            ),
            const SizedBox(height: ZeniSpacing.sm),
            Center(
              child: DangerActionText(
                label: 'Remover exemplo',
                onPressed: () {
                  ZeniErrorPopup.show(
                    context,
                    title: 'Remoção bloqueada',
                    message: 'Este é apenas um exemplo visual por enquanto.',
                  );
                },
              ),
            ),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }
}
