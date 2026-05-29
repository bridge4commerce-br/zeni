# ZeniKids — Checklist de Migração Bolt/Expo para Flutter

## Regra de trabalho

- [x] Usar o protótipo Bolt/Expo como referência visual e funcional.
- [x] Implementar o app final em Flutter.
- [x] Seguir a identidade ZeniKids: missões, mimos, estrelas/saldo e sequência.
- [x] Centralizar cores, espaçamentos, raios, tipografia e sombras.
- [ ] Evitar estilos e cores hardcoded nas telas.
- [ ] Usar um arquivo por componente.
- [ ] Não usar snackbar para erro, sucesso ou aviso.
- [ ] Usar popup/overlay temporizado com contador visível.
- [x] Manter suporte a tema claro e escuro.
- [ ] Preparar acessibilidade desde a base.

---

## 0. Setup do projeto

- [x] Criar projeto Flutter novo.
- [x] Configurar package base como app.luminadigital.zeni.
- [x] Criar estrutura inicial de pastas.
- [x] Adicionar dependências iniciais.
- [x] Corrigir widget_test.dart.
- [x] Rodar flutter analyze sem issues.
- [x] Rodar flutter test sem falhas.
- [ ] Rodar app em simulador/dispositivo.

---

## 1. Fundação visual

### Theme/tokens

- [x] Criar zeni_colors.dart.
- [x] Criar zeni_spacing.dart.
- [x] Criar zeni_radius.dart.
- [x] Criar zeni_typography.dart.
- [x] Criar zeni_shadows.dart.
- [x] Criar zeni_theme.dart.
- [x] Revisar todos os tokens contra o protótipo Bolt/Expo.
- [x] Adicionar tokens de animação.
- [x] Adicionar tokens semânticos para estados: sucesso, erro, aviso e informação.

### App/router

- [x] Criar main.dart.
- [x] Criar zeni_app.dart.
- [x] Criar app_router.dart.
- [x] Criar tela temporária de validação.
- [ ] Definir rotas finais públicas.
- [ ] Definir rotas do modo criança.
- [ ] Definir rotas do modo responsável.

---

## 2. Componentes base

### Base

- [x] Criar ZeniScaffold.
- [x] Criar ZeniCard.
- [x] Criar ZeniPrimaryButton.
- [x] Criar ZeniSecondaryButton.
- [x] Criar ZeniTextButton.
- [x] Criar ZeniIconActionButton.
- [x] Criar ZeniFab.
- [x] Criar StatusBadge.

### Layout

- [x] Criar ZeniTopBar.
- [x] Criar ZeniBottomNavBar.
- [x] Criar ZeniModalSheetContainer.
- [ ] Criar layout responsivo básico.
- [ ] Padronizar SafeArea e padding das telas.

### Identidade visual

- [x] Criar ZeniAvatar.
- [x] Criar ZeniBalancePill.
- [ ] Criar componentes de logo.
- [ ] Configurar assets oficiais.
- [ ] Configurar ícone e splash.

### Inputs

- [x] Criar ZeniTextInput.
- [x] Criar ZeniMultilineInput.
- [x] Criar ZeniOptionRow.
- [x] Criar ZeniSwitch.
- [x] Criar CounterStepper.
- [ ] Criar ZeniSelectMenu.
- [ ] Criar RewardRenewalSelectMenu.

### Feedback

- [x] Criar ZeniFeedbackPopup.
- [x] Criar ZeniErrorPopup.
- [x] Criar ZeniSuccessPopup.
- [x] Criar ZeniInfoPopup.
- [x] Criar ZeniCountdownRing.
- [x] Criar DangerActionText.
- [ ] Garantir que não haja snackbar no app.

---

## 3. Acessibilidade base

- [x] Adicionar assets de fonte OpenDyslexic.
- [x] Configurar carregamento de fontes.
- [x] Criar AccessibilitySettings model.
- [x] Implementar fonte padrão/dislexia.
- [x] Implementar ajuste de tamanho da letra.
- [ ] Implementar vibração.
- [ ] Implementar TTS do device.
- [ ] Implementar leitura em voz alta por perfil da criança.
- [ ] Implementar notificações.
- [ ] Adicionar accessibilityLabel nos componentes base.
- [ ] Validar áreas mínimas de toque.

---

## 4. Models

- [x] Criar ChildProfile.
- [x] Criar Mission.
- [x] Criar MissionLog.
- [x] Criar Reward.
- [x] Criar RewardRequest.
- [x] Criar StarLedgerEntry.
- [x] Criar Family.
- [x] Criar FamilyMember.
- [x] Criar AppSettings.
- [x] Criar enums de status.
- [x] Criar dados mockados iniciais.

---

## 5. Repositórios mockados

- [x] Criar MockChildRepository.
- [x] Criar MockMissionRepository.
- [x] Criar MockRewardRepository.
- [x] Criar MockBalanceRepository.
- [ ] Criar MockSettingsRepository.
- [x] Criar providers Riverpod.
- [ ] Garantir troca futura para Supabase sem quebrar telas.

---

## 6. Onboarding/Auth

- [ ] Migrar onboarding slide 1.
- [ ] Migrar onboarding slide 2.
- [ ] Migrar onboarding slide 3.
- [ ] Criar indicador de progresso.
- [ ] Criar painel de ações.
- [x] Criar escolha de perfil.
- [ ] Criar tela de auth.
- [ ] Criar botão Google.
- [ ] Criar botão Apple.
- [ ] Criar entrar com código.
- [ ] Criar textos legais.
- [ ] Conectar rotas públicas.

---

## 7. Modo criança

- [x] Criar shell com bottom navigation.
- [x] Criar Home da criança.
- [x] Criar lista de missões.
- [x] Criar agrupamento por horário.
- [ ] Criar calendário semanal.
- [x] Criar card de missão da criança.
- [x] Criar bottom sheet de conclusão.
- [x] Criar tela de mimos.
- [x] Criar card de mimo da criança.
- [x] Criar tela de saldo.
- [x] Criar histórico inicial de saldo.
- [ ] Criar tela de perfil da criança.

---

## 8. Modo responsável

- [x] Criar shell com bottom navigation.
- [x] Criar dashboard do responsável.
- [x] Criar lista de missões.
- [x] Criar aprovação de missão inicial.
- [x] Criar tela de mimos.
- [x] Criar aprovação de resgate inicial.
- [x] Criar tela família.
- [ ] Criar seletor de criança.
- [x] Criar configurações iniciais.
- [ ] Criar premium badge.
- [ ] Criar grupos de settings.

---

## 9. Fluxos de criação/edição

- [x] Criar missão.
- [x] Editar missão.
- [x] Excluir missão.
- [x] Criar mimo.
- [x] Editar mimo.
- [x] Excluir mimo.
- [ ] Criar perfil da criança.
- [x] Editar perfil da criança.
- [ ] Selecionar avatar.
- [ ] Criar convite por código/link.
- [ ] Criar fluxo de resgate de mimo.
- [ ] Criar fluxo de sucesso de missão.

---

## 10. Supabase

- [ ] Configurar supabase_flutter.
- [ ] Criar env/config.
- [ ] Implementar auth real.
- [ ] Implementar famílias.
- [ ] Implementar perfis de criança.
- [ ] Implementar missões.
- [ ] Implementar logs de missão.
- [ ] Implementar mimos.
- [ ] Implementar pedidos de resgate.
- [ ] Implementar histórico de estrelas.
- [ ] Implementar convites.
- [ ] Implementar storage.
- [ ] Implementar RLS.
- [ ] Testar permissões de responsável/criança.

---

## 11. Polimento final

- [ ] Revisar microcopy.
- [ ] Revisar estados vazios.
- [ ] Revisar loading states.
- [ ] Revisar erros.
- [ ] Revisar modo escuro.
- [ ] Revisar acessibilidade.
- [ ] Revisar performance.
- [ ] Rodar flutter analyze.
- [ ] Rodar flutter test.
- [ ] Gerar build Android.
- [ ] Gerar build iOS.

---

## Correções de fluxo percebidas no teste manual

- [x] Permitir cancelar missão enviada para aprovação.
- [ ] Permitir desfazer conclusão automática recente.
- [ ] Atualizar saldo/histórico ao desfazer uma missão automática.
- [ ] Impedir que criança desfaça missão já aprovada pelo responsável sem intervenção do responsável.

---

## Home da criança

- [x] Redesenhar Home para ser painel informativo, não lista duplicada de missões.
- [x] Criar mensagem contextual do dia.
- [x] Mostrar progresso diário de missões.
- [x] Mostrar próxima missão recomendada.
- [x] Mostrar missão extra em destaque quando existir.
- [x] Mostrar incentivo de mimo quando a criança estiver perto de resgatar.
- [ ] Mostrar mensagem personalizada de aniversário.
- [ ] Adicionar birthDate ao ChildProfile.
- [ ] Criar lógica de mensagem por contexto: aniversário, missão pendente, missão enviada, dia completo.

---

## Persistência

- [ ] Detalhar estratégia de persistência local e remota.
- [ ] Persistir preferências de acessibilidade localmente.
- [ ] Persistir último perfil selecionado localmente.
- [ ] Definir Supabase como fonte real dos dados familiares.
- [ ] Criar tabela families.
- [ ] Criar tabela family_members.
- [ ] Criar tabela child_profiles.
- [ ] Criar tabela missions.
- [ ] Criar tabela mission_logs.
- [ ] Criar tabela rewards.
- [ ] Criar tabela reward_requests.
- [ ] Criar tabela star_ledger_entries.
- [ ] Usar star_ledger_entries como fonte de verdade do saldo.
- [x] Criar regras para reversão/correção de saldo.
- [ ] Definir RLS por família e papel do usuário.

---

## Revisão UX infantil de Missões

- [x] Criar card compacto de missão para criança.
- [x] Remover descrição longa da lista de missões.
- [x] Mostrar missão concluída com check e texto tachado.
- [x] Destacar missão pendente com cor e ampulheta.
- [x] Abrir detalhes da missão ao tocar no card.
- [x] Manter ações de concluir/cancelar dentro do detalhe.

---

## Revisão UX infantil da Home

- [x] Deixar próxima missão com visual compacto.
- [x] Deixar missão extra com visual compacto.
- [x] Abrir detalhes da missão a partir da Home.
- [x] Manter ações principais dentro do detalhe.

---

## Revisão UX infantil de Mimos

- [x] Criar card compacto de mimo para criança.
- [x] Remover descrição longa da lista de mimos.
- [x] Mostrar visual claro quando a criança pode pedir o mimo.
- [x] Mostrar visual claro quando ainda faltam estrelas.
- [ ] Mostrar visual claro quando o mimo já foi solicitado.
- [x] Abrir detalhes do mimo ao tocar no card.
- [x] Manter ação de pedir mimo dentro do detalhe.
- [x] Criar bottom sheet de detalhes do mimo.
- [x] Atualizar saldo/histórico ao pedir mimo pelo detalhe.

---

## Fluxos reais locais do responsável

- [x] Aprovar missão de verdade no estado local.
- [x] Remover missão aprovada da lista de aprovações pendentes.
- [x] Creditar estrelas no saldo da criança no painel do responsável.
- [x] Registrar entrada local no ledger ao aprovar missão.
- [ ] Rejeitar missão de verdade no estado local.
- [x] Aprovar mimo de verdade no estado local.
- [x] Rejeitar mimo de verdade no estado local.

---

## Navegação do responsável

- [x] Fazer card Crianças do dashboard navegar para Família.
- [x] Fazer card Aprovações do dashboard navegar para Missões.
- [x] Fazer card Missões ativas do dashboard navegar para Missões.
- [x] Fazer card Mimos pedidos do dashboard navegar para Mimos.
- [ ] Criar tela de detalhe/gerenciamento de criança.
- [ ] Fazer card individual da criança abrir gerenciamento específico.

---

## Melhorias do responsável percebidas no teste manual

- [x] Rejeitar missão remove da lista de aprovações pendentes.
- [x] Rejeitar pedido de mimo remove da lista de pedidos pendentes.
- [x] Compactar cards de missão/aprovação do responsável.
- [x] Abrir detalhe da aprovação ao tocar no card.
- [x] Criar seleção múltipla de aprovações.
- [x] Aprovar missões selecionadas em lote.
- [x] Rejeitar missões selecionadas em lote.
- [x] Aprovar pedidos de mimo selecionados em lote.
- [x] Rejeitar pedidos de mimo selecionados em lote.

---

## Revisão UX de pedidos de mimo do responsável

- [x] Compactar card de pedido de mimo do responsável.
- [x] Abrir detalhe do pedido de mimo ao tocar no card.
- [x] Manter rejeição dentro do detalhe.
- [x] Manter aprovação dentro do detalhe.
- [x] Aprovar pedido de mimo de verdade no estado local.

---

## Regras locais de saldo

- [x] Missão aprovada pelo responsável credita estrelas.
- [x] Pedido de mimo debita/reserva estrelas no momento da solicitação.
- [x] Aprovação de mimo não debita novamente.
- [x] Rejeição de mimo devolve estrelas para a criança.
- [ ] Refletir essas regras nos repositórios reais/Supabase.

---

## Seleção múltipla do responsável

- [x] Seleção múltipla de aprovações de missão.
- [x] Aprovar missões selecionadas em lote.
- [x] Rejeitar missões selecionadas em lote.
- [x] Seleção múltipla de pedidos de mimo.
- [ ] Aprovar pedidos de mimo selecionados em lote.
- [ ] Rejeitar pedidos de mimo selecionados em lote.

---

## Gerenciamento da criança

- [x] Criar bottom sheet inicial de gerenciamento da criança.
- [x] Abrir gerenciamento ao tocar no card da criança na aba Família.
- [x] Mostrar resumo de saldo, streak, missões, mimos e histórico recente.
- [ ] Editar perfil da criança.
- [ ] Mostrar histórico completo da criança.
- [ ] Mostrar missões completas da criança.
- [ ] Mostrar mimos completos da criança.

---

## Filtro por criança no responsável

- [x] Criar seletor Todas/Luna/Theo.
- [x] Filtrar aprovações pendentes por criança.
- [x] Filtrar missões ativas por criança.
- [x] Filtrar pedidos de mimo por criança.
- [x] Filtrar catálogo de mimos disponíveis por criança.
- [ ] Conectar dashboard para abrir Missões/Mimos já filtrado por criança.
- [ ] Adicionar troca de criança dentro do gerenciamento da criança.

---

## CRUD de crianças

- [x] Incluir nova criança.
- [x] Editar nome da criança.
- [x] Editar emoji/avatar da criança.
- [x] Adicionar data de nascimento da criança.
- [x] Usar data de nascimento para mensagem de aniversário.
- [x] Arquivar criança em vez de excluir definitivamente.
- [x] Ocultar criança arquivada das telas principais.
- [x] Permitir restaurar criança arquivada.
- [ ] Permitir exclusão definitiva apenas se não houver histórico.
- [ ] Refletir CRUD de crianças no Supabase futuramente.

---

## Inclusão local de criança

- [x] Criar formulário de adicionar criança.
- [x] Adicionar criança em estado local.
- [x] Exibir nova criança na aba Família.
- [x] Exibir nova criança nos filtros de Missões e Mimos.
- [ ] Persistir nova criança no Supabase futuramente.

---

## Edição local de criança

- [x] Reutilizar formulário para adicionar/editar criança.
- [x] Editar nome da criança em estado local.
- [x] Editar emoji/avatar da criança em estado local.
- [x] Atualizar card da criança após salvar edição.
- [ ] Persistir edição de criança no Supabase futuramente.

---

## Arquivamento local de criança

- [x] Arquivar criança com confirmação.
- [x] Preservar histórico, saldo, missões e mimos.
- [x] Ocultar criança arquivada da aba Família.
- [x] Ocultar criança arquivada dos filtros de Missões e Mimos.
- [x] Criar tela/lista de crianças arquivadas.
- [x] Permitir restaurar criança arquivada.
- [ ] Persistir arquivamento no Supabase futuramente.

---

## Restauração local de criança

- [x] Mostrar seção Crianças arquivadas quando existir criança inativa.
- [x] Restaurar criança arquivada em estado local.
- [x] Fazer criança restaurada voltar para Família.
- [x] Fazer criança restaurada voltar aos filtros de Missões e Mimos.
- [ ] Persistir restauração no Supabase futuramente.

---

## Data de nascimento da criança

- [x] Adicionar birthDate opcional ao ChildProfile.
- [x] Adicionar data de nascimento no formulário de criança.
- [x] Salvar data de nascimento ao criar criança.
- [x] Salvar data de nascimento ao editar criança.
- [x] Mostrar aniversário no gerenciamento da criança.
- [x] Usar aniversário na Home da criança.
- [ ] Persistir birthDate no Supabase futuramente.

---

## Troca de perfil

- [x] Adicionar ação Trocar perfil no modo criança.
- [x] Adicionar ação Trocar perfil no modo responsável.
- [x] Voltar para a tela de escolha de perfil usando rota raiz.
- [ ] Garantir persistência local ao trocar de perfil.
- [ ] Garantir persistência local após hot restart/reabrir app.
