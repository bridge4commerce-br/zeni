# Sprint 2B.1 — Diagnóstico e preparação da resolução canônica

Data: 2026-09-25. Base: `40cc056`, Sprint 2A concluída. Referências: [arquitetura v1.0](zeni-multidevice-architecture-v1.0.md), [Sprint 2](zeni-multidevice-sprint-2-contratos-e-identidade.md), [proposta 2B](zeni-multidevice-sprint-2b-resolucao-canonica.md).

As decisões aprovadas nesta etapa substituem os pontos pendentes da proposta 2B: uma membership por usuário na V1, múltiplos responsáveis por família, criação com lock transacional + UNIQUE sem receipt, nenhuma seleção arbitrária ou auto-heal. O fechamento de escrita direta fica condicionado à compatibilidade do cliente.

## 1. SQL de diagnóstico para execução manual

**Executar somente [zeni-sprint-2b1-diagnostico-readonly.sql](zeni-sprint-2b1-diagnostico-readonly.sql) no SQL Editor do Supabase.** O arquivo é um bloco independente BEGIN READ ONLY → SELECTs → COMMIT, sem INSERT/UPDATE/DELETE/DDL ou chamada de RPC. Não é uma migration. Copiar o arquivo inteiro; as consultas compartilham snapshot REPEATABLE READ. O isolamento exibido será o desta transação de diagnóstico, não prova do isolamento usado pelo PostgREST.

Resultados: usuários com zero/uma/várias memberships; famílias vazias, sem owner ou com múltiplos owners; referências órfãs/papéis inválidos; profile sem usuário, usuário sem profile e profile sem membership; duplicidades de user_id e do par family/user; criador sem membership e múltiplas famílias por criador; constraints/indexes, RLS, grants, funções, overloads, triggers e default ACLs aplicados.

Ausência de família/profile pode ser normal antes do setup. Múltiplos owners não violam a regra aprovada. created_by não é autoridade e não exige ser owner atual. Cada anomalia deve ser avaliada; não apagar, escolher ou reassociar dados automaticamente. Nenhuma consulta foi executada no banco remoto.

## 2. Auditoria de compatibilidade, por uso

Busca em todo o projeto por `families`, `family_members`, `ensure_user_family`, métodos intermediários e chamadas RPC. Nenhum acesso de dados a essas tabelas foi encontrado fora das superfícies abaixo; ocorrências em docs são contratos e ocorrências SQL de REFERENCES são FKs, não DML.

| Classe | Uso e evidência | Impacto de revogar escrita hoje |
| --- | --- | --- |
| A — SELECT | `SupabaseAccountRepository.getCurrentRemoteFamilySummary`, family_members com JOIN families, limit(2) e filtro user_id | SELECT deve continuar; DML revogado não bloqueia esta leitura |
| B — INSERT | RPC ensure: upsert profile, INSERT families, INSERT family_members | SECURITY DEFINER usa owner; revogar INSERT de authenticated não substitui aposentadoria da RPC |
| B — INSERT | Policies families_insert_authenticated e family_members_insert_owner | Caminhos autorizados pelo schema; sem chamada INSERT direta encontrada no Flutter/Edge |
| C — UPDATE | `SupabaseAccountRepository.updateRemoteFamilyName`: `.from('families').update({'name': ...}).eq('id', ...)` | Revogar UPDATE quebra esse método |
| C — UPDATE | `ZeniAccountController.updateRemoteFamilyName` e callback de parent_shell_page | Dependência preservada, mesmo sem editor exposto na UI atual; não tratar código ainda acessível como removido |
| C — UPDATE | Policies de família e memberships; branch ON CONFLICT do ensure em membership | Policies não são chamadas; não há UPDATE direto de memberships no cliente encontrado |
| D — DELETE | RPC delete_current_owned_family_for_account_deletion: DELETE families com CASCADE | Executa como definer; não depende de DELETE direto do cliente, mas depende de EXECUTE e contexto Auth corretos |
| D — DELETE | Edge Function usa admin.auth.admin.deleteUser após RPC | É API administrativa Auth; pode causar CASCADE, não é DELETE direto via PostgREST |
| E — RPC | AccountRepository chama ensure_user_family; auth providers chamam depois de login/signup/email/Google/Apple quando base vazia/segura e summary ausente | Remover/revogar ensure agora causa falha de preparação pós-login; autenticação já pode ter ocorrido |
| E — RPC | Edge delete-account cria userClient com JWT do usuário e chama RPC de exclusão; adminClient só deleta Auth user | Incompatibilidade preexistente com grant service_role-only da migration de hardening |
| A/E — providers | remoteFamilySummaryProvider abastece sync/domínios/bootstrap/restore | Preservar SELECT até migrar consumidor para resolve; nenhum create no sync manual atual |
| Testes | account_data_test valida alteração de nome via fake; cloud_manual_sync_test espera ensure para login vazio; fakes de auth/bootstrap/restore implementam contrato legado | Não são SQL real nem prova de ACLs; migrar expectativas junto com o cliente |

Fontes principais: [repository](../../lib/features/auth/data/repositories/supabase_account_repository.dart), [account providers](../../lib/features/auth/presentation/providers/zeni_account_providers.dart), [auth providers](../../lib/features/auth/presentation/providers/zeni_auth_providers.dart), [parent shell](../../lib/features/parent/presentation/pages/parent_shell_page.dart), [Edge Function](../../supabase/functions/delete-account/index.ts), [schema identidade](../../supabase/migrations/20260528174736_create_remote_identity.sql), [hardening](../../supabase/migrations/20260609103000_harden_public_function_execute_permissions.sql).

Migrations de children/missions/rewards/logs/requests/ledger referenciam families por FK; helpers is_family_member/has_family_role fazem SELECT em memberships. Não alterar essas superfícies nem suas permissões nesta preparação.

Conclusão: **revogação total de escrita direta em families não é compatível hoje**, por causa de UPDATE de nome. Não foi encontrada dependência cliente de DML direto em family_members ou INSERT/DELETE direto de families. Mesmo assim, a migration desta etapa é aditiva e não revoga DML de tabelas; a mudança de políticas será uma migration de corte coordenada. Isso preserva compatibilidade sem alegar fechamento já concluído.

A exclusão de conta exige revisão própria: o hardening versionado revoga authenticated e concede apenas service_role para a RPC, enquanto a Edge usa userClient. Se esse schema estiver aplicado, ela retorna rpc_failed antes de deletar Auth. Não corrigimos grants ou Edge nesta sprint; conferir ACL real e planejar correção sem aceitar user_id arbitrário. A proposta 2B anterior auditava SQL, mas não havia identificado essa chamada incompatível.

## 3. Contrato final das novas RPCs

Assinaturas: `public.resolve_current_family()` e `public.create_initial_family()`, ambas sem parâmetros e com retorno JSONB. A identidade vem exclusivamente de auth.uid; auth.role precisa ser authenticated. Sem UID/role adequada: SQLSTATE 28000, mensagem not_authenticated; falta de EXECUTE pode barrar antes do corpo.

Envelope único e campos sempre presentes:

```json
{
  "contract_version": 1,
  "status": "found",
  "reason": null,
  "user_id": "uuid da sessão",
  "family_id": "uuid canônico",
  "membership_id": "uuid da membership",
  "family_name": "Minha família",
  "role": "owner"
}
```

JSONB preserva compatibilidade de transporte com Supabase RPC, explicita estados e evita usar null indistintamente para ausência/erro. Nos estados sem resolução, family_id, membership_id, family_name e role são null; user_id continua sendo o chamador, sem expor dados de terceiros.

| RPC/status | Semântica |
| --- | --- |
| resolve/found | Exatamente uma membership, família e role válidos, ao menos um owner com Auth user existente |
| resolve/not_found | Zero memberships; profile não é condição de existência da família |
| resolve/ambiguous | Mais de uma membership; reason=multiple_memberships; nenhuma escolhida |
| resolve/inconsistent | Usuário Auth ausente ou referência/papel/owner inválidos; reason=auth_user_missing ou invalid_membership_or_owner |
| create/created | Criou profile se faltava, família e owner na mesma transação |
| create/already_exists | Retorna a família existente validada, preservando role, nome e profile; inclusive responsible |
| create/ambiguous ou inconsistent | Mesmos bloqueios de resolve, sem gravações |
| create/inconsistent específico | Sem membership, mas com família created_by=UID: reason=created_family_without_membership; sem adoção implícita |

Resolve é STABLE, somente consultas, sem timestamp/profile update, usando snapshot do chamador. Create é VOLATILE: adquire `pg_advisory_xact_lock(hashtextextended('zeni:create_initial_family:v1:' || UID, 0))`, reconsulta em instrução posterior ao lock e só cria após not_found válido. Namespace/seed são fixos no backend; colisão de hash só amplia serialização.

UNIQUE não deferrable `family_members(user_id)` garante uma membership por usuário mesmo contra escritor que não usa lock. Preservada UNIQUE(family_id,user_id). O novo índice já atende busca por user_id; nenhum índice redundante. Restrição V1 removível em evolução multi-família; não restringe número de responsáveis na mesma família.

Falha de unicidade/FK/serialização reverte a chamada inteira, incluindo família provisória; não é convertida em not_found nem sucesso parcial. Em concorrência entre APIs nova e legada pode ocorrer erro de constraint: repetir a operação inteira re-resolve a família vencedora. Duas chamadas da nova RPC sob READ COMMITTED retornam created/already_exists com a mesma família. Não há receipt; exclusão deliberada encerra o lifecycle dessa identidade. Este mecanismo não substitui operation_id do Sync V2.

Ambas usam SECURITY DEFINER, owner postgres, search_path vazio e nomes qualificados. Grants das novas funções são revogados de PUBLIC/anon/authenticated/service_role e concedidos somente a authenticated, na transação de publicação. Não há SQL dinâmico. Conferir herança/default ACLs no ambiente real; o dono da função continua privilegiado.

## 4. Migration local preparada

[20260925120000_prepare_canonical_family_resolution.sql](../../supabase/migrations/20260925120000_prepare_canonical_family_resolution.sql) foi criada, sem aplicação remota. Deve ser executada integralmente numa única transação pelo runner; não executar trechos soltos.

Ordem: lock de tabelas de identidade → preconditions que abortam em user_id duplicado, referência/papel inválido, família sem owner ou profile órfão → UNIQUE(user_id) → duas novas funções → owners/ACLs apenas dessas funções. Não faz saneamento, backfill de usuários existentes nem alteração de policies/DML de tabelas. A preparação de profile dentro de create faz parte da nova operação, não é backfill de migration.

Nenhuma definição ou grant da ensure antiga foi alterado. UPDATE de families, policies existentes, RPC de exclusão e Edge permanecem intactos. O arquivo prepara a API nova; **não elimina ainda a criação implícita do login ou todos os caminhos diretos de escrita**. A constraint bloqueia múltiplas memberships, mas INSERT direto ainda pode criar famílias órfãs sem membership durante coexistência. Isso fica explicitamente pendente do corte.

Preconditions não substituem diagnóstico: vários owners são permitidos; created_by sem membership pode ser legítimo após mudanças administrativas ou exigir recuperação; profiles faltantes não são auto-preenchidos durante migration. O banco real precisa de inventário e aprovação para qualquer saneamento.

## 5. Ordem coordenada para o cliente e aposentadoria

1. Diagnosticar ambiente real e revisar anomalias/ACLs antes de autorizar aplicação da preparação.
2. Disponibilizar nova API após integração validada; manter legado durante migração do cliente.
3. Migrar ZeniAccountRepository, SupabaseAccountRepository e zeni_account_providers para resultado tipado found/not_found/ambiguous/inconsistent. Não confundir erro de transporte com ausência.
4. Migrar zeni_auth_providers: todo login/signup/recuperação só resolve. Create somente por intenção explícita; nenhum fallback automático nem relabel de local-family.
5. Preparar persistência segura da identidade canônica para família recém-criada vazia antes do primeiro cadastro. Bootstrap atual recusa catálogo vazio; não relaxar guard para contornar isso. UI/onboarding não foram alterados aqui.
6. Substituir updateRemoteFamilyName por RPC autorizada própria ou retirar definitivamente a capacidade após decisão de produto. Migrar callback de parent_shell_page e testes; até lá não revogar UPDATE.
7. Migrar consumidores de summary nos providers de domínio/sync/bootstrap; preservar FamilyIdentityGuard, revalidações e restore histórico. Guard não é substituído pela RPC.
8. Conferir ausência de clientes antigos; migration separada para fechar INSERT/UPDATE/DELETE diretos em families/family_members, retirar policies de escrita correspondentes e aposentar ensure. Sem CASCADE e sem adapter que esconda CREATE.

Arquivos Flutter a migrar futuramente: zeni_account_repository.dart, supabase_account_repository.dart, zeni_account_providers.dart, zeni_auth_providers.dart, parent_shell_page.dart (callback de nome), consumidores de remoteFamilySummaryProvider conforme tipo final e respectivos fakes/testes. Não houve edição em lib/ ou test/ nesta etapa.

## 6. Testes implementados e limites

Arquivos locais: [bootstrap isolado](../../supabase/tests/canonical_family_test_bootstrap.sql), [contrato](../../supabase/tests/canonical_family_contract_test.sql), [concorrência A](../../supabase/tests/canonical_family_concurrency_a.sql), [concorrência B](../../supabase/tests/canonical_family_concurrency_b.sql).

**Não executar esses arquivos no SQL Editor remoto.** São testes que criam fixtures e fazem alterações transitórias em base descartável com nome obrigatório zeni_sprint2b_test. O bootstrap usa shim mínimo de Auth; não valida assinatura JWT nem comportamento HTTP. Aplicar migrations em ordem cronológica com transação por arquivo e ON_ERROR_STOP; rodar contrato; abrir duas conexões A/B com B enquanto A mantém a transação em pg_sleep. B exige evidência do overlap, para não passar como teste meramente sequencial. Repetição da corrida requer nova base descartável ou fixtures novas.

Verificados em PostgreSQL 17.6 local, contêiner sem rede e sem volumes do projeto:

- todas as migrations, inclusive a nova, aplicadas com sucesso numa base vazia;
- found/not_found, ausência de gravação por resolve, profile preservado no retry;
- created/already_exists, uma family/owner, responsável existente sem promoção;
- B isolado de A, UID ausente, ACLs das novas funções;
- owner ausente, família órfã, ambiguidade artificial sem seleção automática;
- UNIQUE e rollback da família provisória de escritor não cooperante;
- duas conexões reais: A created com commit retido; B bloqueia e recebe already_exists; uma família e uma membership;
- resolve/found executado como authenticated dentro de transação READ ONLY.

Pendentes obrigatórios antes de aplicação: integração Supabase Auth/PostgREST/RLS com ACLs reais; falhas/retries sob isolamento efetivo; nova-versus-legada concorrentes; preconditions em cópia com anomalias; rejeição de user_id forjado pela API; ausência de caminhos alternativos de escrita após o corte; regressão da exclusão de conta.

Testes Flutter existentes de FamilyIdentityGuard/mismatch/grafo, bootstrap e restore foram preservados e executados na suíte completa. A expectativa atual de login vazio chamar ensure permanece porque o cliente não foi migrado. O teste futuro de **login nunca cria**, inclusive base vazia, ainda não é satisfeito pelo código atual; deve mudar junto com a implementação do cliente, sem falsificar a expectativa nesta etapa.

## 7. Prontidão, riscos e rollback

**NÃO é seguro aplicar a migration no Supabase remoto ainda.** Os diagnósticos reais não foram recebidos; o teste local usa shim Auth; grants reais e o problema preexistente de exclusão precisam de avaliação. O arquivo é preparatório, não autorização de deploy. Nenhum db push, aplicação remota ou commit foi realizado.

Riscos remanescentes: legado ainda cria implicitamente; DML direto ainda aberto; build antigo pode receber falha de UNIQUE durante corrida com API nova; ausência de setup canônico de família vazia; dados reais podem bloquear preconditions. Estes limites não são ocultados pela suíte verde.

Falha durante migration transacional reverte DDL. Após futura aplicação, rollback conservador desabilita create nova e preserva dados/resolve/guard; não apagar famílias criadas. Retirar UNIQUE ou reabrir escrita exige nova decisão e análise de dados. Não usar rollback que reinsira famílias ou reassocie memberships. Esta etapa já mantém ensure por compatibilidade, mas a aposentadoria final deve ser coordenada e não desfeita silenciosamente.

## 8. Validação desta entrega

`flutter analyze`: sem problemas. `flutter test`: 479 testes passando. `git diff --check`: sem erros; os arquivos novos também foram verificados separadamente, pois ainda não estão rastreados. `rg -n "SnackBar|ScaffoldMessenger" lib test`: nenhuma ocorrência. `git status --short` e `git diff --stat` executados; o diff rastreado está vazio porque a entrega adiciona arquivos novos, sem stage/commit. O documento 2B já estava não rastreado e foi preservado. O contêiner e os dados descartáveis de teste foram removidos ao final; nenhum dado remoto ou de usuário foi removido.
