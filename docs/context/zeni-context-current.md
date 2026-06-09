# ZeniKids/Zeni — Contexto Atual do Projeto

## 1. Resumo do produto

O Zeni é um app Flutter familiar para crianças e responsáveis, focado em rotina, missões, mimos e saldo de estrelas. O produto foi desenhado para funcionar primeiro no aparelho, com login opcional e Supabase entrando como camada progressiva para autenticação, sync, bootstrap em novo aparelho, diagnóstico e restauração controlada.

## 2. Princípios do projeto

- `offline-first`
- login opcional
- saldo local como fonte operacional
- Supabase como camada progressiva
- sem merge automático
- sem realtime por enquanto
- sem saldo remoto como fonte operacional
- sem `SnackBar`/`ScaffoldMessenger`

Detalhes importantes:

- O estado operacional do app vive localmente em `SharedPreferences` via `ZeniAppStateController`.
- O Supabase existe para preparar família remota, sincronizar cópias estruturadas, permitir bootstrap de aparelho novo e viabilizar restauração histórica segura.
- O ledger remoto serve para auditoria, restauração e derivação de saldo na nuvem, não para dirigir a UX principal do aparelho.
- O app evita notificações efêmeras padrão do Flutter e usa folhas modais, mensagens inline e popups próprios.

## 3. Estado atual por área

### Local/offline

- Base local madura e funcional.
- `lib/core/state/zeni_app_state.dart` e `lib/core/state/zeni_app_state_controller.dart` concentram família, crianças, membros, missões, logs, mimos, pedidos, ledger e `appSettings`.
- Persistência local já cobre criação, edição, arquivamento, aprovação, saldo, restore local e wipe do aparelho.
- Há migração de preferências legadas e normalização do estado carregado.

### UX criança

- Shell próprio com abas de início, missões e mimos.
- Missões automáticas creditam estrelas localmente com animação e ledger.
- Missões com aprovação ficam pendentes até o responsável aprovar.
- Pedido de mimo debita saldo local no momento da solicitação e registra ledger.
- Fluxo está consistente com o modelo offline-first.

### UX responsável

- Shell completo com visão de família, missões, mimos, métricas, aprovações, saldo, sync, restauração, conta, legal/suporte e segurança.
- Há gestão de criança, missão, mimo, aprovações em lote, PIN e biometria.
- Ajustes exibem status local, status remoto, diagnóstico de consistência e ações de bootstrap/restauração quando aplicável.

### Auth

- Auth opcional e progressivo.
- Fluxos implementados para e-mail/senha, Google e Apple, com mensagens controladas.
- Login não é pré-requisito para usar o app localmente.
- `ensure_user_family()` é chamado após autenticação válida para preparar a família remota.
- Logout remove sessão sem apagar dados locais.

### Supabase

- Camada remota já existe e está modelada para família, crianças, missões, mimos, logs, pedidos e ledger.
- RLS está presente nas tabelas principais.
- Há helpers `security definer` para validar pertencimento e papéis.
- View de saldo derivado remoto existe para diagnóstico e restauração.

### Sync

- Sync progressivo já implementado por domínio.
- Ordem explícita: crianças, missões, mimos, logs, pedidos e ledger.
- Sync interrompe no primeiro erro para reduzir cascata de inconsistência.
- Timestamps de último sync por área e sync total já existem em `appSettings`.
- Não há merge automático nem colaboração multi-dispositivo completa.

### Ledger/saldo

- Saldo local continua sendo a fonte operacional.
- Ledger local é atualizado em missão aprovada/automática, pedido de mimo e reembolso por rejeição.
- Ledger remoto existe com `idempotency_key`, `source_type`, direção crédito/débito e view `child_star_balances`.
- Diagnóstico de consistência compara saldo local com saldo derivado remoto.

### Restauração

- Bootstrap de aparelho novo restaura somente família, crianças, missões e mimos.
- Restauração histórica separada restaura logs, pedidos, ledger e recompõe saldo local.
- Guard rails fortes impedem restore histórico com atividade local, catálogos desalinhados ou divergência insegura entre ledger e saldo remoto.
- Streak não é restaurado.

### Conta e dados

- Área de conta já distingue claramente dados locais e nuvem.
- Wipe local com confirmação `APAGAR` já existe e retorna o app ao estado inicial.
- Logout preserva dados locais.
- A exclusão remota existe em backend e camadas de repositório/teste, mas a UI principal atual a apresenta como indisponível nesta versão.

### Segurança/RLS

- RLS habilitada nas tabelas remotas principais.
- Helpers `is_family_member`, `has_family_role`, `child_belongs_to_family`, `mission_belongs_to_child` e `reward_available_to_child` sustentam políticas.
- `20260609103000_harden_public_function_execute_permissions.sql` endurece grants de `EXECUTE`.
- `delete_current_owned_family_for_account_deletion()` ficou restrita a `service_role`, o que a tira do uso direto pelo cliente autenticado e reforça que o fluxo não deve ser considerado ativo na UI atual.

### Testes

- Suite organizada por feature em `test/auth/`, `test/settings/`, `test/support/` e arquivos focados de sync/restore.
- Há cobertura forte para auth, sync incremental, idempotência, bootstrap, restore histórico, saldo/ledger, wipe local e textos de ajustes.
- Também há testes confirmando que a exclusão remota aparece como indisponível na UI atual.

### QA manual

- Checklist manual para beta interno já criado em `docs/qa/qa-beta-interno-01.md`.
- Cobre instalação limpa, fluxo local, auth, sync, bootstrap, restore histórico, wipe local, segurança, fluxo criança/responsável e regressão visual.
- Critérios de bloqueio para beta estão definidos.

### Legal/suporte

- Há conteúdo interno para Política de Privacidade, Termos, Suporte e explicação de dados locais/nuvem.
- Existe e-mail de suporte em UI.
- Ainda precisa revisão final de copy, coerência jurídica e readiness para publicação beta.

## 4. Supabase atual

### Tabelas e view relevantes

- `profiles`
- `families`
- `family_members`
- `children`
- `missions`
- `rewards`
- `mission_logs`
- `reward_requests`
- `star_ledger_entries`
- `child_star_balances` (`view`)

### Funções relevantes

- `ensure_user_family()`
- helpers de RLS:
  - `is_family_member(uuid)`
  - `has_family_role(uuid, text[])`
  - `child_belongs_to_family(uuid, uuid)`
  - `mission_belongs_to_child(uuid, uuid, uuid)`
  - `reward_available_to_child(uuid, uuid, uuid)`
- `delete_current_owned_family_for_account_deletion()`

Notas:

- `ensure_user_family()` cria ou reaproveita família remota para o usuário autenticado e garante `profile` + membership.
- `child_star_balances` deriva saldo, créditos, débitos e contagem de eventos do ledger remoto.
- `delete_current_owned_family_for_account_deletion()` existe para exclusão controlada da família remota, mas deve ser tratado como fora da UI atual e restrito a `service_role` após o hardening de grants.
- A edge function `supabase/functions/delete-account` também existe, mas hoje o contexto correto do projeto é considerar exclusão remota como fluxo não liberado para a versão de beta interno.

## 5. O que já está validado

- `flutter analyze` já foi tratado como parte das fases anteriores do projeto
- `flutter test` já foi tratado como parte das fases anteriores do projeto
- ausência de `SnackBar`/`ScaffoldMessenger` por leitura do código atual
- grants endurecidos em `20260609103000_harden_public_function_execute_permissions.sql`
- testes reorganizados por feature
- checklist QA criado em `docs/qa/qa-beta-interno-01.md`

Evidências observadas na auditoria:

- UI principal de ajustes marca exclusão remota como indisponível.
- Há testes cobrindo bootstrap, restore histórico, sync ordenado, idempotência e preservação de dados locais no logout.
- Há testes cobrindo legal/suporte e ações de conta/dados.

## 6. O que ainda falta antes do beta interno

- executar checklist `C01–C32`
- corrigir falhas críticas encontradas
- validar device real
- revisar UX final
- revisar legal/suporte
- preparar TestFlight/Play interno

Complementos práticos:

- confirmar login Google e Apple em device real
- validar sync/restauração com conta e dados remotos reais
- verificar textos, overflow, acessibilidade e estados vazios em fluxo completo
- fechar a posição oficial sobre exclusão remota para beta: indisponível, escondida ou apenas informativa

## 7. O que NÃO fazer agora

- merge automático
- realtime
- multi-dispositivo colaborativo completo
- saldo remoto como fonte operacional
- features novas de gamificação
- premium/assinatura
- exclusão remota na UI sem fase própria
- grandes mudanças visuais antes do QA

Também evitar:

- refatorações amplas em sync, saldo, ledger, streak, auth ou restauração antes do QA manual
- mudanças de contrato Supabase perto do beta
- expansão de escopo em onboarding além do necessário para estabilidade

## 8. Próxima fase recomendada

Executar a fase de **QA manual guiado para beta interno**, usando o checklist `C01–C32` como gate formal e corrigindo somente falhas críticas ou bloqueadoras encontradas nessa rodada.

## 9. Contexto compacto para colar em nova conversa

## Contexto compacto para IA

O projeto atual é o Zeni/ZeniKids, um app Flutter familiar para crianças e responsáveis com missões, mimos, estrelas, modo criança e modo responsável. A arquitetura do produto é `offline-first`: o app precisa continuar útil sem login e sem internet. O estado operacional fica localmente em `SharedPreferences` via `ZeniAppStateController`, que persiste família, crianças, membros, missões, logs, mimos, pedidos, ledger e `appSettings`. O saldo local da criança é a fonte operacional da UX. O Supabase não é a fonte operacional do saldo; ele é uma camada progressiva para autenticação, sync, bootstrap em novo aparelho, diagnóstico e restauração. Não há merge automático, não há realtime por enquanto e não existe colaboração multi-dispositivo completa nesta fase.

O app já passou por várias etapas: base local/offline, refatoração de telas, auth opcional, Supabase progressivo, sync de catálogos, sync de eventos, ledger remoto, diagnóstico de saldo, diagnóstico de consistência, bootstrap de novo aparelho, restauração histórica/saldo, Conta e dados, auditoria de RLS e endurecimento de grants `EXECUTE`, reorganização dos testes por feature e checklist de QA manual para beta interno. A leitura atual do código mostra que essas peças estão implementadas e integradas, com guard rails relevantes.

Auth é opcional. Há fluxo de e-mail/senha, Google e Apple com mensagens controladas. Após login válido, o app chama `ensure_user_family()` para preparar a família remota. Logout remove só a sessão e preserva os dados locais. A UX e os testes reforçam essa decisão. O app também evita `SnackBar`/`ScaffoldMessenger`; feedbacks usam popups próprios, folhas e mensagens inline.

No Supabase, existem `profiles`, `families`, `family_members`, `children`, `missions`, `rewards`, `mission_logs`, `reward_requests`, `star_ledger_entries` e a view `child_star_balances`. As políticas RLS usam helpers `security definer`: `is_family_member`, `has_family_role`, `child_belongs_to_family`, `mission_belongs_to_child` e `reward_available_to_child`. Há também `ensure_user_family()`. O ledger remoto usa `idempotency_key` e a view `child_star_balances` deriva saldo remoto para auditoria e restauração, mas esse saldo remoto não deve dirigir a UX principal do aparelho.

O sync já existe por domínio e roda em ordem: crianças, missões, mimos, logs de missão, pedidos de mimo e ledger. A ideia é sincronizar cópias consistentes e parar no primeiro erro, sem tentar resolver conflito automaticamente. Há timestamps de último sync por área e de sync total em `appSettings`. O diagnóstico de consistência compara contagens locais/remotas e saldo local com saldo derivado remoto, servindo como ferramenta de QA e suporte.

O fluxo de restauração foi separado em duas fases. `device bootstrap` restaura apenas dados principais em aparelho vazio: família, crianças, missões e mimos. Não traz saldo, histórico, pedidos nem streak. Já a restauração histórica traz logs, pedidos e ledger, recompõe `balanceAfter` localmente e atualiza `starBalance` das crianças, mas só quando o aparelho ainda não tem atividade local, quando os catálogos estão alinhados e quando o ledger remoto bate com os saldos remotos derivados. `streak` não é restaurado. Isso é intencional e deve ser preservado.

A área “Conta e dados” está implementada. Wipe local com confirmação `APAGAR` existe e reseta o app no aparelho sem apagar nuvem. Logout não apaga local. Legal/suporte também já existem em folhas internas: Política de Privacidade, Termos, Suporte e explicação de dados locais/nuvem. Há PIN do responsável e biometria com fallback para PIN.

Ponto crítico de contexto: exclusão remota. O código de backend inclui a RPC `delete_current_owned_family_for_account_deletion()` e a edge function `delete-account`. Porém a migration de hardening (`20260609103000_harden_public_function_execute_permissions.sql`) revoga `EXECUTE` dessa RPC de `authenticated` e concede apenas a `service_role`. Além disso, a UI principal de Ajustes hoje mostra “Excluir conta e dados da nuvem” como indisponível nesta versão, e há teste cobrindo isso. Portanto, em novas conversas, trate exclusão remota como fluxo fora da UI/fase atual, não como feature pronta para beta interno. Se alguém pedir para “finalizar” essa parte, isso deve ser considerado uma fase própria, não um ajuste pequeno.

O estado atual do projeto é próximo de beta interno técnico. As principais forças são: base offline consistente, separação clara entre local e nuvem, auth opcional, sync incremental ordenado, ledger com idempotência, restore histórico com travas fortes, cobertura de testes relevante e checklist QA manual pronto. Os principais riscos antes do beta são menos de arquitetura e mais de validação real: comportamento em device real, login social real, edge cases de sync/restauração com dados remotos reais, coerência de UX/copy e alinhamento final de legal/suporte. Também há um cuidado de contexto: existem caminhos de código antigos/auxiliares para exclusão remota, mas o produto atual deve comunicar indisponibilidade dessa ação no beta.

Prioridade imediata recomendada: rodar o checklist manual `docs/qa/qa-beta-interno-01.md`, especialmente `C01–C32`, registrar evidências e corrigir apenas falhas críticas ou bloqueadoras de beta. Depois disso, revisar UX final, textos legais/suporte e preparar distribuição interna via TestFlight/Play. Não abrir agora frentes de merge automático, realtime, multi-dispositivo colaborativo completo, saldo remoto operacional, gamificação nova, assinatura/premium ou redesign grande.

Comandos de validação úteis no projeto:

- `flutter analyze`
- `flutter test`
- `git status`

Cuidados críticos para qualquer nova intervenção:

- não trocar o princípio `offline-first`
- não transformar saldo remoto em fonte operacional
- não implementar merge automático
- não mexer em sync/ledger/restauração sem necessidade real
- não restaurar `streak`
- não apagar nuvem a partir de wipe local
- não apagar dados locais ao fazer logout
- manter a UI sem `SnackBar`/`ScaffoldMessenger`
- tratar exclusão remota como fora da UI/fase atual até decisão explícita de produto/segurança
