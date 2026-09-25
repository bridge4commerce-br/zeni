# Zeni — Sprint 2: auditoria e proposta de contratos de identidade

Data: 2026-09-25. Base auditada: checkout `d85eda9`.

Status: proposta para implementação posterior; nenhuma implementação nesta etapa.

Referência normativa: [arquitetura multi-dispositivo v1.0](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/docs/architecture/zeni-multidevice-architecture-v1.0.md). As decisões da Sprint 1 permanecem aprovadas; as soluções incrementais abaixo são propostas da Sprint 2, não mudanças retroativas daquele contrato.

## 1. Escopo, evidência e conclusão da auditoria

Foram inspecionados os modelos, repositories, providers, persistência, autenticação, onboarding, bootstrap, restore, sync e migrations presentes no repositório. A auditoria de banco descreve as migrations versionadas, **não confirma o schema efetivamente aplicado em um projeto Supabase remoto**. Não houve conexão ao banco, execução de SQL, alteração de código, packages, migrations, UI ou testes. Os testes existentes foram consultados como evidência de cobertura, sem executá-los.

A base tem separação de acesso por membership no backend, mas não possui um vínculo persistido e validado entre a base operacional local e a família da sessão. O sync combina dados locais com a família remota resolvida naquele momento. Isso permite que uma troca de conta encaminhe conteúdo local da família A para uma família B autorizada à nova conta: a RLS valida B, mas não conhece a origem local A. É um risco demonstrado pelo caminho do código, não um incidente confirmado em produção.

Prioridade da Sprint 2: estabelecer identidade canônica, resolução inequívoca de membership e uma barreira de identidade para todos os acessos remotos. O sync atual só pode continuar para uma base cuja identidade já foi validada. A compatibilidade não deve preservar o comportamento inseguro de associar `local-family` à primeira conta.

## 2. Auditoria do schema versionado

### 2.1 IDs, relacionamentos e constraints

Nas tabelas abaixo, `id` é PK UUID. Exceto `profiles`, que reutiliza o UUID de Auth, os IDs possuem default `gen_random_uuid()`. Isso não significa que o UUID dos objetos Dart seja o mesmo UUID remoto: os inserts atuais dos domínios omitem a PK.

| Tabela | Identidade e vínculos | UNIQUE, índices e observações |
| --- | --- | --- |
| `profiles` | `id → auth.users.id`, DELETE CASCADE; email/display_name | Sem `family_id` e sem `local_id`; PK por pessoa, não por família |
| `families` | UUID próprio; `created_by → auth.users.id`, DELETE SET NULL | Sem unicidade por criador; sem `local_id`; `created_by` não substitui membership |
| `family_members` | UUID próprio; `family_id → families.id` e `user_id → auth.users.id`, ambos CASCADE | UNIQUE `(family_id,user_id)`; role CHECK `owner/responsible`, default `owner`; não limita famílias por usuário nem assegura último owner |
| `children` | UUID remoto; família obrigatória; `local_id` textual nullable; `created_by` SET NULL | UNIQUE parcial `(family_id,local_id)` quando não nulo; índices family/created_by; `archived_at` |
| `missions` | família e criança obrigatórias; `local_id`; created_by | Mesmo UNIQUE parcial; índices family/child/created_by; `is_active`, `archived_at`; CHECK stars ≥ 1 e recorrência |
| `rewards` | família obrigatória; criança opcional para mimo global; `local_id`; created_by | Mesmo UNIQUE parcial; índices family/child/created_by; CHECK cost ≥ 1; ativo/arquivado |
| `mission_logs` | família, criança e missão obrigatórias; `local_id`; created_by | Mesmo UNIQUE parcial; índices family/child/mission/created_by; CHECK status e stars_awarded ≥ 0; sem UNIQUE por ocorrência canônica |
| `reward_requests` | família, criança e mimo obrigatórios; `local_id`; created_by | Mesmo UNIQUE parcial; índices family/child/reward/created_by; CHECK status e stars_spent ≥ 0; note/rejection_reason; sem transação financeira de aceitação |
| `star_ledger_entries` | família e criança obrigatórias; `source_id` UUID nullable **sem FK**, `source_local_id` textual; created_by | UNIQUE `(family_id,idempotency_key)`; índices family/child/created_by; CHECK tipo, direção, amount > 0; não tem `local_id` nem `business_effect_key` |

As FKs dos domínios para família/criança/catálogo usam CASCADE. As FKs são individuais: não garantem por si que criança e entidade referenciada pertençam à mesma família. Essa coerência é complementada por helpers nas policies de escrita. Um caminho privilegiado que ignore RLS não ganha automaticamente essa proteção relacional. Todas as tabelas de domínio listadas, exceto `family_members`, possuem `updated_at` com trigger; nenhuma possui revisão-base ou cursor.

Fontes: [identidade](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/supabase/migrations/20260528174736_create_remote_identity.sql), [children](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/supabase/migrations/20260528204748_create_children.sql), [missions](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/supabase/migrations/20260528211101_create_missions.sql), [rewards](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/supabase/migrations/20260529122243_create_rewards.sql), [mission_logs](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/supabase/migrations/20260529130409_create_mission_logs.sql), [reward_requests](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/supabase/migrations/20260529134056_create_reward_requests.sql), [ledger](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/supabase/migrations/20260529153000_create_star_ledger_entries.sql).

### 2.2 RLS e helpers atuais

| Superfície | Proteção encontrada | Limite relevante |
| --- | --- | --- |
| profiles | SELECT/INSERT/UPDATE somente `id = auth.uid()` | Não é resolução de família; não há repository local específico de Profile |
| families | SELECT por `is_family_member`; INSERT com `created_by = auth.uid()`; UPDATE owner/responsible | INSERT direto pode criar família sem membership e contornar um futuro fluxo exclusivo de criação |
| family_members | SELECT por membership; INSERT/UPDATE/DELETE por owner | Pode remover/demover último owner; não há lifecycle de convite/aceite; role local de UI não tem autoridade |
| children | SELECT por membro; INSERT/UPDATE owner/responsible | INSERT confere created_by; UPDATE não impõe imutabilidade de family_id/created_by |
| missions/rewards | Mesmo padrão; helpers verificam criança na família, aceitando child null em reward | Sem revisão-base nem regra de transição; UPDATE permite mudanças relacionais se policy final continuar satisfeita |
| mission_logs | Mesmo padrão; `mission_belongs_to_child` confere missão/criança/família | Responsável pode escrever status e crédito; helper não verifica arquivamento nem ocorrência |
| reward_requests | Mesmo padrão; `reward_available_to_child` confere família e destino global/individual | Helper não verifica ativo/arquivado; não verifica saldo/custo aplicável nem serializa aceitação |
| ledger | SELECT por membro; INSERT/UPDATE por manager e criança da família | Permite ledger arbitrário e mutação; `source_id` não é validado contra causa canônica |

Não há policies DELETE ordinárias para os seis domínios operacionais auditados; isso não impede deleção por cascade de família através de função privilegiada. `is_family_member`, `has_family_role` e helpers relacionais são `SECURITY DEFINER` com search_path definido. Os helpers relacionais verificam relações, mas não incluem todos uma checagem do usuário: isoladamente podem servir como oráculo booleano de existência/relação para quem já conheça UUIDs. Usá-los em conjunção com membership é necessário; futuramente restringir chamadas diretas ou verificar escopo dentro deles.

A migration de [hardening](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/supabase/migrations/20260609103000_harden_public_function_execute_permissions.sql) revoga EXECUTE de PUBLIC/anon, mantém helpers/ensure para authenticated e restringe a RPC de exclusão a service_role. Não foram encontradas tabelas/policies de devices, vínculos ou credencial infantil. RLS habilitada não equivale a autorização infantil implementada.

A view [child_star_balances](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/supabase/migrations/20260529162000_create_child_star_balances_view.sql) usa `security_invoker`, SELECT para authenticated e soma ledger por criança. É conferência, não saldo operacional editável. A [RPC de exclusão](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/supabase/migrations/20260608103000_create_delete_current_owned_family_for_account_deletion_rpc.sql) exige exatamente uma membership, owner e família com um único membro. Essa restrição deve continuar explícita enquanto não houver contrato de exclusão para múltiplos responsáveis.

## 3. Auditoria Flutter e mapa exato das identidades

### 3.1 Modelos e persistência

Os repositories `MockFamilyRepository`, `MockMissionRepository`, `MockRewardRepository` e `MockBalanceRepository` são conectados aos providers operacionais e usam o controller local; o prefixo Mock não significa que o app use exclusivamente fixtures. Ver [providers](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/core/providers/zeni_repository_providers.dart) e [repository de família](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/family/data/repositories/mock_family_repository.dart).

| Modelo | Identidade local auditada | Diferença para o remoto |
| --- | --- | --- |
| Family | `id`, nome, inviteCode, createdAt | Sem identidade de usuário/membership; inviteCode não é pairing |
| FamilyMember | id, familyId, papel parent/child, isOwner, childProfileId, email opcional | Não tem `auth.user_id`; inclui perfis infantis, que não são memberships Auth |
| ChildProfile | id, familyId, nome, avatar, saldo/streak/TTS/ativo | Um único campo id; não persiste em campo separado o UUID remoto |
| Mission / Reward | id, familyId e childId (opcional no reward) | IDs locais são convertidos para FKs remotas nos adapters |
| MissionLog / RewardRequest | id, childId e missionId/rewardId | Não têm familyId próprio; dependem da integridade do grafo local |
| StarLedgerEntry | id, familyId, childId, referências locais, amount e balanceAfter | Fonte/valor são convertidos no upload; modelo local não tem operation_id/business_effect_key |

Fontes: diretórios [family/models](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/family/data/models), [tasks/models](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/tasks/data/models), [rewards/models](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/rewards/data/models) e [StarLedgerEntry](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/balance/data/models/star_ledger_entry.dart).

O [controller](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/core/state/zeni_app_state_controller.dart:23) persiste um JSON agregado em `SharedPreferences`, chave `zeni_app_state_v1`, sem namespace de família/usuário. `_save` publica o estado em memória antes de aguardar `_persist`. Não há transação estado/outbox nem envelope de identidade verificada. `hasUserContent` considera children/missions/rewards, não todo o histórico.

### 3.2 Onde cada ID aparece

| Identificador | Localização e uso verificado |
| --- | --- |
| `local-family` | [ZeniAppState.initial](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/core/state/zeni_app_state.dart:45): Family.id e FamilyMember.familyId iniciais. O setup usa `current.family.id` para novos registros, propagando esse valor |
| `local-parent` | Mesmo factory, linha 53. Recriado como fallback em `applyDeviceBootstrapIfEmpty` e `applyRemoteCatalogSnapshot` do controller, linhas 363/420; não identifica usuário Auth nem membership remota |
| UUID local | `createChild`, `completeInitialOnboardingSetup` e builders do controller usam `Uuid.v4()`; logs, pedidos e entradas de ledger também recebem UUID local |
| UUID remoto de família | `ensure_user_family()` retorna `family_id`; AccountRepository o converte para `RemoteFamilySummary.familyId`. Bootstrap o grava em Family.id; sync ordinário preserva o Family.id local existente |
| UUID remoto dos domínios | PK gerada pelo banco no insert; summaries expõem `id`, `familyId`, `localId` e FKs remotas; providers montam mapas `localId → id` |
| `local_id` | Os repositories de children/missions/rewards/mission_logs/reward_requests buscam `(family_id, local_id)`, gravam o id Dart nesse campo e atualizam pela PK remota encontrada |
| `source_local_id` / idempotency_key | Ledger usa ID local de log/pedido ou do ajuste; não tem local_id próprio. Chaves atuais: `mission_log:<local>:earned/reversal`, `reward_request:<local>:spent/refunded`, `manual_adjustment:<local>` |

O [repository de children](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/family/data/repositories/supabase_remote_children_repository.dart:74) é a evidência direta: `_buildPayload` recebe familyId externo, grava `local_id: child.id` e omite `id`. Os demais seguem o mesmo padrão de associação: [missions](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/tasks/data/repositories/supabase_remote_missions_repository.dart), [rewards](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/rewards/data/repositories/supabase_remote_rewards_repository.dart), [logs](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/tasks/data/repositories/supabase_remote_mission_logs_repository.dart), [pedidos](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/rewards/data/repositories/supabase_remote_reward_requests_repository.dart), [ledger](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/balance/data/repositories/supabase_remote_star_ledger_repository.dart:139).

### 3.3 Login, criação e logout

`ensure_user_family()` faz upsert de profile; busca a primeira membership por created_at; se não encontra, cria família “Minha família” e membership owner na mesma chamada. A operação é transacional, mas a consulta seguida de criação **não possui serialização por usuário**: duas chamadas concorrentes podem criar famílias diferentes. UNIQUE `(family_id,user_id)` não evita isso. `getCurrentRemoteFamilySummary()` ainda usa `limit(1)` sem order, podendo escolher família diferente da RPC quando há várias memberships.

O [auth controller](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/auth/presentation/providers/zeni_auth_providers.dart) chama ensure após login e signup autenticado por e-mail/Google/Apple. A restauração da sessão via stream apenas atualiza o auth state; não executa esse mesmo ensure. A confirmação de e-mail também deve ser distinguida de sessão utilizável. Falha no ensure pode retornar falha da operação mantendo o usuário já autenticado.

O logout chama o repository Auth e invalida providers remotos; não limpa `zeni_app_state_v1`. O caminho normal preserva dados locais, conforme Sprint 1. Não há mudança de Family.id nem vínculo formal a um usuário. A invalidação não constitui cancelamento/isolamento de requests em andamento. Fontes: [account repository](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/auth/data/repositories/supabase_account_repository.dart:14), [auth repository](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/auth/data/repositories/supabase_auth_repository.dart:279).

### 3.4 Sync, bootstrap e restore

O [sync](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/sync/presentation/providers/cloud_sync_providers.dart) executa children → missions → rewards → logs → pedidos → ledger → pull. O sync manual chama ensure antes. Há single-flight em memória e [debounce de 900 ms](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/sync/presentation/providers/opportunistic_sync_providers.dart), com agendamento no [retorno ao foreground](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/app/zeni_app.dart:36). Não são outbox, cursor ou autorização por aparelho.

O [provider de children](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/family/presentation/providers/remote_children_providers.dart:66) lê todas as crianças locais e passa `remoteFamily.familyId` ao upload, sem comparação com Family.id/ChildProfile.familyId. Os providers seguintes constroem mapas a partir de `localId` não nulo. Os repositories fazem read-then-insert/update; UNIQUE evita duplicação da mesma chave, mas colisão concorrente pode resultar em erro, não num ACK idempotente de domínio.

O bootstrap exige base sem `hasUserContent`, busca catálogos e usa `local_id` quando presente, senão UUID remoto. Grava família remota, zera saldo/streak e sintetiza membros de UI; inclusive normaliza parent local como owner sem trazer a membership Auth. Não restaura todos os campos não representados no remoto (ex.: usa defaults de aparência de catálogo). Fontes: [provider de bootstrap](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/sync/presentation/providers/device_bootstrap_providers.dart), [mapper](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/sync/data/mappers/remote_device_bootstrap_mapper.dart:19).

O [primeiro acesso](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/sync/presentation/providers/first_access_restore_providers.dart) verifica também ausência de logs/pedidos/ledger antes de bootstrap e restore histórico, aceitando sucesso parcial seguro em alguns bloqueios de histórico. O [restore histórico](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/sync/presentation/providers/historical_restore_providers.dart) exige catálogos e histórico local vazio/saldo zero. Seu [mapper](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/sync/data/mappers/remote_historical_restore_mapper.dart) valida correspondências, recompõe balanceAfter e saldo por ledger e confere a view; não recompõe streak.

No sync ordinário, o catálogo é aplicado **antes** da validação/aplicação do histórico. Portanto, falha posterior pode deixar catálogo já atualizado. O mapper do catálogo e `applyRemoteCatalogSnapshot` preservam o familyId local, mesmo recebendo família remota. Nem isso nem alinhamento por local_id provam igualdade canônica de família. Alguns getters convertem falhas de leitura em listas vazias, impedindo distinguir ausência de dados de indisponibilidade; snapshots precisam distinguir esses resultados antes de substituir estado.

Caso importante: uma criança remota sem local_id é restaurada com `id = remote.id`, mas o upload procura esse valor somente em local_id. Pode tentar criar outra criança, e os mapas dos providers não incluem a original sem local_id. Corrigir apenas o factory do ChildProfile não resolve essa duplicação.

## 4. Contrato proposto de family_id e contexto local

`family_id` é exclusivamente o UUID canônico de `families.id`, distinto de `auth.user_id`, imutável e não secreto. A criação inicial exige backend disponível e responsável autenticado; o backend deriva o criador de Auth e cria família + membership owner atomicamente. Dados de uma família não são transferidos alterando family_id em payloads.

Proposta de contexto persistido junto à base: versão de identidade, family_id canônico, estado de associação (`uninitialized`, `bound`, `mismatch`, `recovery_required`), identidade do último responsável validado e evidência temporal da validação. Nome exato dos campos é conceitual. O familyId do envelope deve corresponder a Family.id e às entidades; logs/pedidos precisam resolver criança e catálogo dentro desse mesmo grafo. Metadados locais não concedem autorização remota.

| Situação | Resultado obrigatório |
| --- | --- |
| Instalação sem base, fluxo Criar minha família | Autenticar; resolver/criar explicitamente família; persistir contexto retornado antes de criar conteúdo |
| Instalação sem base, fluxo Já uso o Zeni | Resolver membership sem criar; receber família; bootstrap seguro e histórico separado |
| Sessão e base com mesmo family_id, mesma conta | Validar membership e vínculo parent; liberar remoto |
| Outra conta com membership da mesma família | Reautenticação e resolução explícitas; novo contexto parent associado ao novo usuário; mesma família não requer copiar conteúdo |
| Sessão aponta B e base contém A | `family_mismatch`; bloquear upload, pull e restore sobre A; preservar A; não relabelar nem iniciar cache B automaticamente |
| `local-family`, ID inválido ou origem não comprovada | `unbound_local_data`; impedir sync; transição controlada de desenvolvimento/beta, nunca vinculação automática |
| Sessão expirada, logout ou rede indisponível | Preservar família e dados; uso local autorizado continua; operações remotas aguardam revalidação |
| Membership removida/família ausente | Bloquear remoto; preservar base para recuperação explícita; não recriar família como efeito colateral |

O mismatch deve oferecer recuperação orientada para voltar à conta correta. Qualquer substituição de base para outra família depende de fluxo explícito separado, preservação/exportação ou descarte autorizado dos dados existentes; não é um seletor nem cache simultâneo de múltiplas famílias na V1.

Uma barreira comum deve validar identidade antes de cada operação remota e antes de aplicar cada resposta. Capturar um contexto imutável com usuário, família e geração da sessão; troca/logout invalida a geração. Respostas da geração anterior não podem alterar a base atual. O backend ainda valida a autorização independentemente dessa barreira; ela evita mistura acidental no cliente, não substitui RLS.

## 5. Membership e evolução de ensure_user_family

Os papéis atuais `owner` e `responsible` são suficientes para a V1. Proposta: owner administra propriedade/membros e ações exclusivas; responsible é responsável gestor do cotidiano. `parent` é o papel do aparelho/UI, não um terceiro papel de membership; não adicionar admin redundante. Convites, novos papéis e múltiplos responsáveis na UI ficam para evolução própria. Criança não vira usuário de Auth nem linha em family_members.

Preservar UNIQUE `(family_id,user_id)` e tornar user/family de uma membership imutáveis. Atualizar papel é operação autorizada separada; impedir remoção/demissão do último owner. Não usar `isOwner` local nem role fornecida no payload como autoridade. Uma única família ativa por responsável é regra do produto V1; não colocar UNIQUE(child_id) em vínculos nem limitar estruturalmente toda evolução de memberships a uma família para sempre.

Contratos backend propostos, nomes sem compromisso físico de RPC:

| Operação | Entrada confiável e comportamento | Resultado conceitual |
| --- | --- | --- |
| Resolver identidade do responsável | Auth obrigatório; busca memberships; não cria família | user_id, membership_id, family_id, nome, role e estado de resolução |
| Criar ou obter família por intenção explícita | Auth + intenção criar + chave estável da solicitação; serializar por usuário e reconsultar membership na transação | Retorna existente quando inequívoca; ou cria família + owner uma vez; retry retorna mesmo resultado |
| Validar contexto esperado | Auth + family_id esperado como asserção, não autorização | membership válida e mesma família, ou erro explícito |
| Registrar/validar vínculo parent | Auth + contexto de família + prova da instalação | device_link_id e estado/last_validated_at definidos no servidor |

Resolver zero memberships retorna `no_family`, não falha de rede e não criação automática. Resolver mais de uma retorna `ambiguous_membership` e bloqueia a V1 até correção explícita; não selecionar a primeira e não expor seletor. Esta é uma estratégia conservadora para dados anômalos, não uma nova capacidade de produto.

Reaproveitar de ensure: autenticação por auth.uid(), upsert de profile, retorno canônico e criação família/owner numa transação. Mudar: separar leitura/criação; eliminar `limit(1)` silencioso; serializar criação por usuário; impedir INSERT direto de families que contorne o contrato; garantir idempotência da intenção. Em concorrência, a segunda requisição deve observar a primeira família, mesmo com outra chave de solicitação. UNIQUE da solicitação sozinha não impede duas criações distintas.

O ensure atual **não deve continuar criando como efeito colateral de login, login de recuperação ou sync manual**. Pode sobreviver como adapter temporário somente após todos os chamadores terem semântica compatível e com criação reservada à intenção explícita. Não mudar sua semântica isoladamente enquanto a UI antiga depende dela.

## 6. Contrato proposto de child_id e coexistência incremental

`child_id` canônico é `children.id`: UUID estável, não secreto, pertencente a um único family_id. Logs, pedidos, ledger e vínculos apontam para essa identidade, inclusive após arquivamento. Pareamento não altera child_id. Uma criança pode ter vários vínculos ativos. Não deduplicar crianças por nome, aniversário ou avatar.

Proposta de caminho incremental:

1. Antes de uploads, resolver e validar family_id; uma base `local-family` não é migrada automaticamente.
2. Para base de desenvolvimento/beta autorizada e já associada, manter os IDs locais existentes e registrar correspondência explícita `(family_id, tipo, local_id) → canonical_id`. Não renumerar logs, pedidos ou ledger no primeiro passo.
3. Para registros já remotos, usar sempre a PK existente. Se há correspondência por local_id, validar unicidade e família; se local_id está ausente, resolver pela PK retornada pelo servidor, nunca reinserir por falta do alias.
4. Durante compatibilidade, a camada de identidade expõe canonicalChildId separado do identificador legado usado pelo sync atual. Mapas precisam ser bijetivos dentro do escopo; ambiguidades bloqueiam, não escolhem o primeiro registro.
5. Para novas crianças na arquitetura final, propor UUID v4 criado uma vez no cliente, inclusive offline, e aceito como `children.id` pelo backend após validar membership e família. O UUID pendente não autoriza operações remotas nem pareamento antes da confirmação; colisão/ocupação em outra família é erro, nunca reassociação. Isso preserva estabilidade sem exigir internet para todo cadastro posterior à configuração inicial.
6. Só ativar o caminho novo quando insert, lookup, upload, bootstrap e ambos os mappers tiverem suporte coordenado a canonical_id. Até lá, preservar o protocolo legado e obter o UUID remoto como mapeamento explícito após upload; não alegar identidade canônica completa só porque o ID local tem formato UUID.

O quinto passo é uma proposta para novos registros, não uma ordem de trocar as PKs atuais. Para registros existentes, prevalece sempre o UUID remoto original. A promoção dos IDs de uso no domínio, caso necessária, exige atualização consistente de todas as referências locais e leitura compatível. A Sprint 2 pode estabelecer o mapeamento; transação durável para conversão ampla deve esperar a fundação local da Sprint 3. Não construir ferramenta genérica de importação de famílias legadas.

## 7. Contrato de device_id e armazenamento

`device_id` é UUID aleatório por instalação, gerado uma vez e persistido independentemente de Auth/família/perfil. Não deriva de nome/modelo/hardware ID, usuário ou criança. É identificador público: apresentar o UUID não prova posse do aparelho.

### 7.1 Dependências e gaps verificados

O [pubspec](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/pubspec.yaml) já declara uuid, shared_preferences, crypto e local_auth. `uuid` serve para geração; SharedPreferences já persiste dados não secretos; crypto é usado no PIN; local_auth verifica biometria, não é um cofre para credenciais. Não há flutter_secure_storage nem implementação nativa de chave de instalação/Keychain/Keystore encontrada no código do projeto.

[ParentPinSecurity](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/core/security/parent_pin_security.dart) usa SHA-256 com salt aleatório; hash/salt e flag biométrica ficam em AppSettings. A sessão é gerida pelo SDK, não pelo JSON operacional. [ZeniSupabaseBootstrap](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/core/supabase/zeni_supabase.dart) usa initialize padrão; o código local instalado de supabase_flutter 2.12.4 escolhe SharedPreferencesLocalStorage, não armazenamento seguro customizado. Não presumir que o SDK já satisfaz o cofre de credenciais previsto pela Sprint 1.

Propor interface de armazenamento de identidade com: marcador de instalação não transferível, device_id e referência de chave pública; segredo/chave privada em armazenamento seguro nativo. A escolha de package ou bridge e a política de backup são dependências de implementação, sem adicionar package agora. Gerar apenas UUID local pode ser aditivo; registrar vínculo confiável exige também prova criptográfica da instalação, conforme a Sprint 1.

### 7.2 Ciclo de vida

| Evento | Contrato |
| --- | --- |
| Primeira instalação | Criar UUID, marcador e chave; registro remoto somente com autorização; não depende de abrir conta para gerar UUID |
| Nova abertura/atualização normal | Reutilizar identidade intacta; nunca gerar outro UUID por mero relançamento |
| Logout | Preservar device_id e família local; remover sessão; vínculo parent não autoriza sozinho |
| Troca de conta | Mesmo device_id, validar nova membership e contexto; nunca transferir vínculo/autorização do usuário anterior |
| Reinstalação efetivamente nova | Marcador ausente/inválido: nova identidade e chave; não ressuscitar credencial antiga; criança precisa de novo pareamento |
| Restore/transferência de backup | Dados restaurados são candidatos à recuperação, não prova de posse. Sem marcador/chave válidos da mesma instalação, nova identidade, login/pareamento e validação antes de sync |
| Armazenamento inconsistente | Se marcador/chave/registro divergirem, bloquear operação remota e recuperar explicitamente; não autorizar só porque device_id apareceu no backup |
| Aparelho perdido | Revogar vínculo específico no servidor; outros vínculos da criança continuam; não prometer apagar cache offline |

No iOS, persistência de itens de Keychain após desinstalação não é garantia de ciclo de vida da instalação; a Apple recomenda tolerar ambos os comportamentos e associar o segredo a material local eliminado com o app. Portanto, um item sobrevivente não pode sozinho restaurar o vínculo. Fonte: [Apple Developer Technical Support](https://developer.apple.com/forums/thread/36442).

No Android, Auto Backup pode restaurar arquivos e preferências após reinstalação/transferência; identidade copiada não prova continuidade. Planejar exclusões específicas para marcador/credenciais e recuperação quando material seguro estiver ausente. O manifest atual não declara regras próprias de backup. Não equiparar SharedPreferences a armazenamento seguro nem depender de sua ausência após reinstalação. A proposta deve tolerar preferências restauradas sem a chave necessária para utilizá-las, sem recriar autorização a partir desses dados. As regras exatas e testes físicos iOS/Android são pré-requisitos para ativação de vínculos. Fonte: [Android Auto Backup](https://developer.android.com/identity/data/autobackup).

## 8. Entidades conceituais device e device_link

`device` representa a instalação e sua chave pública, sem conter identidade de família como dono permanente. Campos conceituais: device_id, public_key/key_version, created_at e metadados mínimos de plataforma/versão do app. A chave privada nunca sobe. Não disponibilizar inventário global de devices aos membros de qualquer família.

`device_link` é a concessão revogável de escopo. Proposta de campos, com nomes físicos a fechar na implementação:

| Campo conceitual | Motivo e autoridade |
| --- | --- |
| device_link_id | UUID emitido pelo backend; distingue revogação/repareamento de identidade física |
| device_id | FK conceitual para instalação; deve provar posse da chave |
| family_id | Família canônica autorizada; imutável no vínculo |
| device_role | parent ou child; separado de membership.role |
| child_id nullable | Obrigatório em child e ausente em parent; coerente com família |
| parent_user_id nullable | Obrigatório em parent e ausente em child; evita que outra conta herde vínculo parent no mesmo aparelho |
| created_by / revoked_by | Ator autorizado para auditoria; não conferir autoridade por esse campo |
| created_at / last_validated_at | Tempo do servidor; somente validação bem-sucedida atualiza last_validated_at |
| revoked_at | Revogação permanente daquele vínculo; novo pareamento cria outro ID |
| status | Preferir derivado de revoked_at (active/revoked); se persistido, garantir coerência para não ter duas autoridades |
| credential/key version | Permite futura rotação e invalidação de credenciais sem mudar child_id |
| metadata | Nome escolhido do aparelho, plataforma/versão; não segredo, hardware ID ou dados excessivos |

Unicidade proposta: impedir duplicatas ativas do mesmo escopo parent `(device_id,family_id,parent_user_id)` ou child `(device_id,family_id,child_id)`. Não impor UNIQUE(child_id). A instalação infantil opera um único escopo ativo; uma troca de criança/família exige encerrar o contexto anterior e autorizar outro, não editar o vínculo antigo. Reenvio do registro parent deve retornar o vínculo existente; nunca remover revoked_at para reciclar um vínculo revogado.

`last_validated_at` não é `last_seen_at`: abrir o app ou enviar heartbeat local não renova validade. A futura resposta de validação inclui política/offline_valid_until de 48h inicial, configurável pelo backend. A Sprint 2 prepara o contrato, sem emitir credencial infantil.

## 9. Contratos de autorização

### 9.1 Parent device

Cada operação administrativa requer simultaneamente sessão Auth válida, membership atual na família, papel suficiente e, após ativar a exigência de dispositivos, vínculo parent ativo para aquela instalação/usuário/família. Device link, PIN e biometria não substituem Auth. Uma decisão de UI ou um ID enviado no corpo não fornece membership.

O backend resolve o usuário a partir da sessão e valida a família esperada e a prova de posse da instalação. Não basta receber device_link_id em header arbitrário. Remover membership deve bloquear acesso mesmo que o link ainda apareça ativo. Revogar link deve bloquear remoto mesmo com sessão Auth ainda válida. Logout não revoga automaticamente os vínculos infantis.

Limitação de transição: os endpoints de tabela atuais aceitam Auth + membership e não verificam dispositivo. Adicionar tabela de vínculos **não torna revogação efetiva**. A ativação de enforcement por aparelho exige um contexto verificado no backend e cobertura de todos os caminhos de leitura/escrita, sem alternativa direta que ignore a revogação. É uma entrega coordenada de autorização, não algo que se obtém apenas mudando o schema. Não declarar “revogação funcionando” enquanto o sync legado puder contorná-la.

### 9.2 Child device futuro

Não criar auth.user para criança nem copiar sessão do responsável. Futuro pareamento, emitido pelo backend para criança/família canônicas, gera credencial limitada ao device_link e prova da chave. Gateway/RPC valida credencial, expiração, versão e revogação e deriva family_id/child_id do vínculo. Campos enviados pelo cliente são asserções a conferir, nunca concessões de escopo.

Leitura limitada a missões da criança, mimos globais ou destinados a ela, saldo/histórico próprio e decisões pertinentes. Escrita somente por comandos permitidos: conclusão, cancelamento autorizado e pedido de mimo. Proibir administração, aprovação, acesso a irmãos, ledger arbitrário e dados do responsável. Uma chave service_role jamais vai ao app; gateway privilegiado deve revalidar todas as relações por não depender da RLS de usuário.

Preservar as decisões aprovadas: pairing de 10 minutos, código/QR com mesmo pairing_id e consumo único/cancelamento; validade offline infantil inicial de 48h desde validação; após o prazo, somente abrir/visualizar cache, sem novas ações sincronizáveis. São contratos futuros, não funcionalidades presentes ou a implementar nesta etapa.

## 10. Onboarding futuro e modelo local

Hoje [FamilyAccountPage](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/onboarding/presentation/pages/family_account_page.dart:103) oferece “Continuar sem conta” e vai ao setup local. [InitialStartChoicePage](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/onboarding/presentation/pages/initial_start_choice_page.dart) já tem opções semelhantes às futuras, “Sou criança” indisponível e restauração explícita após login; porém o login pode criar família antes da intenção de recuperação. O controller de setup usa a família local corrente.

| Intenção futura | Contrato anterior ao conteúdo operacional |
| --- | --- |
| Criar minha família | Autenticar; resolver identidade; criar/obter família canônica por intenção explícita; validar contexto/vínculo parent; persistir identidade; iniciar onboarding |
| Já uso o Zeni | Autenticar; resolver membership sem criação; validar base vazia/mesma família; recuperar catálogo/histórico apropriados; nunca misturar com base de outra família |
| Sou criança | Reservado para pairing futuro; não liberar acesso remoto com seleção local de perfil |

Antes de mudar a UI, precisam existir resolução de identidade com erros distintos, criação idempotente/serializada, validação da família esperada, registro/validação de parent link e recuperação que diferencie leitura vazia de falha. Family sem catálogo também precisa poder ser reconhecida como identidade válida, mesmo que o bootstrap atual rejeite catálogo totalmente vazio. Conta criada com e-mail pendente não libera setup canônico.

A conta e a rede são exigidas na configuração inicial. Depois, preservar operação local após logout/expiração/indisponibilidade. Dados carregados devem passar validação de envelope e relações; erro de identidade bloqueia sync, não apaga a base. V1 mantém uma única base ativa e não abre silenciosamente a base da conta recém-autenticada sobre dados existentes.

## 11. Preferências locais e segurança local

O gap é de escopo, não de transporte: [AppSettings](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/features/settings/data/models/app_settings.dart:26) contém um único themeMode/textScale/dyslexiaFontEnabled. O [controller de acessibilidade](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/lib/core/accessibility/zeni_accessibility_controller.dart) lê/escreve esses campos globais, e MaterialApp os aplica à árvore inteira. Não existe mapa de aparência por perfil.

Proposta: preferências indexadas por instalação e profile_scope; criança por child_id canônico e responsável por identidade local de perfil associada ao usuário quando validado. Aliases legados devem permanecer resolvíveis durante a transição. Não usar um único `local-parent` para transportar preferências entre pessoas diferentes. Responsável pode editar a preferência da criança naquele aparelho; outro aparelho começa com defaults independentes.

Tema, tamanho e OpenDyslexic não entram em sync/outbox/cursor/checkpoint. PIN, biometria e sessão continuam locais, separados de membership e conteúdo de família. Introduzir device_id não autoriza sincronizar AppSettings. Os `last*SyncAt` atuais são timestamps informativos; não são checkpoints e não devem ser reutilizados como autorização ou controle de entrega.

## 12. Migrations futuras — desenho, sem SQL

| Fase | Trabalho provável | Condição/limite |
| --- | --- | --- |
| A — Sprint 2, identidade | Contratos de resolução/criação; serialização por usuário; recibo idempotente da criação; restrição de criação direta | Substituir os chamadores coordenadamente; nenhuma criação implícita no login de recuperação |
| A — Sprint 2, integridade | Imutabilidade de family_id/IDs; membership explícita; proteção de último owner; coerência relacional por constraints adequadas | Auditar dados beta antes de validar constraints; não reescrever histórico automaticamente |
| A — Sprint 2, devices | Estruturas devices/device_links; FKs, role/child/parent coerentes; índices por family, device, user e child; unicidade de escopo ativo | Estrutura preparada para criança, emissão/consumo infantil desabilitados |
| A — Sprint 2, autorização | RLS/helpers de devices e parent links; registro idempotente, prova da instalação, validação/revogação; acesso mínimo | Enforcement só quando todos os clientes/endpoints suportarem; evitar bypass por acesso direto às tabelas |
| A — Sprint 2, aliases | Preservar PKs/local_id existentes; definir correspondência canônica no cliente/adapters | Banco já tem PK UUID e UNIQUE familiar; não criar tabela nova só para renomear IDs sem necessidade demonstrada |
| B — Pairing, Sprint 6 | Tentativas pairing, digest/segredo, expiração 10 min configurável, cancelamento, consumo atômico e limites | Código/QR representam a mesma tentativa; sem implementação na Sprint 2 |
| B — Pairing, Sprint 6 | Credenciais infantis/rotação/prova de posse; gateway e policies restritas; política offline 48h | Depende da fundação de comandos seguros, não liberar criança no sync administrativo legado |
| C — Sync V2, Sprint 3 e seguintes | Recibos de operation_id, protocolo ACK, persistência local transacional/outbox, feed/cursor/checkpoint | Outbox é principalmente migração da base local; não confundir com tabela remota obrigatória |
| C — Catálogos, Sprint 4 | Revisões, comandos condicionais, tombstones 90 dias e cursores 30 dias configuráveis | Retenção e snapshot consistente com pendências preservadas |
| C — Ledger, Sprint 5 | business_effect_key construída/validada no backend, unicidade, append-only, serialização por child_id, transições atômicas | Não endurecer ledger isoladamente antes de substituir o repository que hoje faz UPDATE |
| C — Restore, Sprint 7 | Snapshot/cursor consistente, reconciliação de outbox e aplicação local transacional | Nunca sobrescrever pendências silenciosamente |

Os nomes de migrations, tabelas auxiliares e índices são deliberadamente não fixados. `device_id`, `device_link_id` e business_effect_key são semânticas de contrato, não SQL proposto. Índices por membership.user_id devem ser avaliados para a resolução, pois UNIQUE `(family_id,user_id)` não começa pelo usuário.

## 13. Invariantes e testes futuros

| Cenário de teste | Resultado exigido | Fase |
| --- | --- | --- |
| Usuário somente de A tenta SELECT/INSERT/UPDATE em B, inclusive FK de B em linha A | Negar; não alterar nenhuma família | Sprint 2 |
| Sessão B com base A chama sync manual, por domínio, restore ou callback tardio | Bloquear antes de upload/aplicação; preservar A | Sprint 2 |
| Base `local-family` com conteúdo e primeiro login | Sem associação automática | Sprint 2 |
| Family.id diverge do envelope ou filho/referência pertence a outra família | Falha de integridade explícita; sem sync | Sprint 2 |
| Login sem membership em Já uso o Zeni | no_family; nenhuma família criada | Sprint 2 |
| Criações simultâneas para mesmo usuário, retries e resposta perdida | Uma família/owner; retorno estável, sem duplicação | Sprint 2 |
| Duas memberships encontradas | ambiguous_membership; não selecionar limit(1) | Sprint 2 |
| Logout/expiração/rede indisponível | Preservar Family.id e dados locais; bloquear remoto quando inválido | Sprint 2 |
| Troca de conta durante seis uploads ou entre fetch/apply | Contexto congelado; resposta antiga não aplicada no novo contexto | Sprint 2 |
| Conta diferente autorizada à mesma família | Resolver explicitamente membership e link desse usuário; não herdar role anterior | Sprint 2 |
| Restore de child sem local_id seguido de sync | Mesma PK; nenhuma nova criança ou relação duplicada | Sprint 2, adapters |
| Arquivar criança e recuperar histórico em outro aparelho | Mesmo child_id e mesmas referências | Sprint 2 / restore |
| Abrir novamente, logout/login, troca de conta | Mesmo device_id quando instalação é a mesma | Sprint 2 |
| Reinstalar iOS com segredo sobrevivente; restaurar Android com prefs antigas | Sem ressuscitar autorização; nova instalação recebe identidade nova | Sprint 2, teste físico |
| Copiar device_id/link sem chave | Negar posse/autorização | Sprint 2 |
| Parent com link ativo mas sem membership, ou membership válida com link revogado | Negar todos os endpoints após enforcement; testar bypass direto | Sprint 2 |
| Tentativa de remover/demover último owner | Negar | Sprint 2 |
| Criança A tenta acessar irmão, outra família ou aprovar pedido | Negar inclusive IDs forjados no corpo | Pairing |
| Dois aparelhos para mesmo child_id; revogar um | Outro permanece válido, sem UNIQUE(child_id) | Pairing |
| Expiração infantil 48h; leitura local; revalidação sem sucesso | Abrir/cache permitidos; nenhuma nova ação sincronizável; prazo não renovado | Pairing |
| Retry com mesmo operation_id e operações distintas para mesma causa | Sem segundo efeito; validar business_effect_key no servidor | Sync V2 / ledger |
| Pedidos concorrentes com saldo para um | Um aceito; outro insufficient_balance; feedback e reconciliação explícitos | Ledger |
| Cursor expirado e outbox não confirmada | Novo snapshot/cursor; preservar e reconciliar pendências | Sync V2 / restore |
| Trocar perfil/aparelho e alterar aparência | Preferência isolada; nenhum evento remoto/outbox | Persistência local |

Há testes atuais de autenticação, idempotência por local_id, sync manual, bootstrap e restore em [auth_test.dart](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/test/auth_test.dart), [cloud_manual_sync_test.dart](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/test/cloud_manual_sync_test.dart), [device_bootstrap_test.dart](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/test/device_bootstrap_test.dart), [first_access_restore_test.dart](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/test/first_access_restore_test.dart) e [historical_restore_test.dart](/Users/guisilva/Documents/EdTech/aplicativos/zenikids_flutter/test/historical_restore_test.dart). Testes com fakes não demonstram RLS, concorrência PostgreSQL ou lifecycle físico do armazenamento. A implementação deverá acrescentar testes de integração correspondentes, sem considerar a cobertura atual prova dos novos invariantes.

## 14. Conflitos com a arquitetura aprovada e riscos

| Código atual versus contrato Sprint 1 | Risco / encaminhamento |
| --- | --- |
| Setup sem conta e `local-family` versus criação canônica online | Vinculação implícita e dados sem origem comprovada; resolver identidade antes do novo onboarding |
| ensure no login/sync e first membership versus intenção explícita/família inequívoca | Segunda família e resolução divergente; separar contratos e serializar |
| Repositories reenviam base local sob family_id da sessão | Contaminação entre contas mesmo com RLS; barreira de identidade em todos os caminhos |
| id Dart/local_id versus child_id canônico remoto | Duplicação, especialmente remoto sem alias; mapear antes de alterar IDs |
| Parent local sintetizado como owner versus membership explícita | Não confiar em UI para autorização; resolver papel no backend |
| Ausência de device/link/chave versus revogação individual | UUID sozinho não resolve; definir prova e enforcement sem bypass |
| Preferências globais versus perfil + aparelho | Mudança de um perfil afeta demais; separar armazenamento local no momento apropriado |
| `requestReward` debita saldo e cria ledger local imediatamente versus débito definitivo após servidor | Implementação atual não distingue financeiro provisório; mudança pertence à sprint de eventos/ledger |
| Upload de status/estrelas arbitrários e ledger UPDATE versus transições protegidas/append-only | Mesmo responsável autorizado pode produzir inconsistência; refatorar comandos e RLS conjuntamente na Sprint 5 |
| Sem business_effect_key validada pelo backend | Chaves atuais usam causa local e são mutáveis; não provam deduplicação canônica entre aparelhos |
| Snapshots sequenciais, falhas como vazio, sem outbox/revisão versus sync transacional | Perda de alterações/conflitos silenciosos; Sprint 3 funda persistência e protocolo, sprints posteriores completam |
| Sem validação infantil/política offline versus 48h | Não prometer modo infantil multi-device antes do gateway e credencial |

O documento aprovado é uma arquitetura alvo: essas diferenças são gaps de implementação, não autorização para corrigi-las nesta auditoria. Dois cuidados de leitura do próprio documento: expirar a janela offline não prova que o servidor revogou o vínculo; apenas impede novas ações até revalidar. E os passos de obter/aplicar snapshot e novo cursor devem culminar numa gravação atômica do par, conforme seção 11.2, sem intervalo com estado novo e cursor antigo. A referência canônica foi preservada.

Riscos adicionais: metadados de identidade fora do JSON podem ficar inconsistentes após falha; não usar duas gravações independentes como se fossem transação. Dados beta com colisões/associação ambígua exigem procedimento explícito. Enforcement parent link introduzido antes dos adapters bloquearia sync válido; introduzido só no cliente deixaria bypass. A indisponibilidade de uma dependência de armazenamento seguro impede afirmar prontidão de credenciais, mas não impede fechar contratos.

## 15. Plano incremental da Sprint 2 e fronteira com Sprint 3

Esta primeira etapa termina com a presente auditoria/proposta. A lista abaixo descreve trabalho futuro, sem executá-lo.

1. Formalizar os contratos de resolução, criação e erros (`no_family`, `ambiguous_membership`, `family_mismatch`, `unbound_local_data`, `membership_required`, `device_revoked`, `identity_changed`, falha de rede distinta). Fixar critérios de testes antes das alterações.
2. Implementar resolução sem efeitos colaterais e criação serializada/idempotente em caminho próprio. Manter resposta compatível com summaries existentes; retirar auto-criação dos chamadores apenas em mudança coordenada.
3. Introduzir envelope de identidade da base e barreira comum de contexto para sync/restore/requests. Inicialização canônica em base vazia; bases beta ambíguas bloqueadas para tratamento explícito. Verificar todos os domínios, não apenas botão Sincronizar.
4. Adicionar UUID de instalação e abstração de armazenamento/chaves; validar reinstalação/backup em iOS/Android antes do registro confiável. Não trocar device_id no logout.
5. Adicionar devices/links parent e registro idempotente. Habilitar enforcement somente após adaptação de todas as rotas de acesso e testes de revogação/RLS. Prova de posse faz parte da identidade confiável de aparelho; não é pairing infantil.
6. Persistir mapeamentos canônicos de crianças, preservar PKs/aliases existentes e corrigir o caso remote-id sem local_id em adapters coordenados. Evitar renumerar grafo/ledger nesta sprint.
7. Somente com esses contratos prontos, planejar a mudança de onboarding em etapa expressamente autorizada. Nesta auditoria, UI permanece intacta.

**Pode ser aditivo sem quebrar o protocolo atual:** UUID local de instalação; modelos conceituais/campos opcionais de identidade; resolver read-only independente; tabelas devices/links e registro desativado para enforcement; mapeamento explícito que preserve IDs usados pelo sync; testes novos quando a implementação for autorizada. Isso não autoriza chamar registros incompletos de vínculos seguros.

**Exige mudança coordenada ainda na identidade:** tornar conta obrigatória na criação, eliminar ensure automático, persistir família canônica, bloquear mismatch, resolver criança sem local_id e exigir parent link no backend. Não é possível garantir os novos invariantes sem tocar nesses pontos futuramente. Compatibilidade deve preservar sync da família correta, e não uploads de base não vinculada.

**Deve esperar a Sprint 3:** persistência transacional de estado + outbox, recibos de operação, ACK durável, retry recuperável, infraestrutura de cursor/checkpoint e proteção contra overwrite de pendências. Revisões/tombstones completos ficam na Sprint 4; efeitos financeiros e business_effect_key na Sprint 5; código/QR e credencial infantil na Sprint 6; restore snapshot/cursor completo na Sprint 7. Não concentrar todo Sync V2 na Sprint 2 ou presumir que a Sprint 3 entrega as demais fases.

Critério de saída da futura implementação da Sprint 2: família/usuário/instalação identificados sem ambiguidade, dados locais associados explicitamente, sync legado permitido somente ao contexto correto, estabilidade de child_id demonstrada por mapeamento, autorização parent verificável e plano infantil preparado sem habilitar criança remota. Nenhuma promessa de colaboração ampla antes das fundações seguintes.

## Referências de plataforma

- [Apple DTS — Keychain após desinstalação](https://developer.apple.com/forums/thread/36442): comportamento de sobrevivência não é contrato de instalação; tolerar remoção ou persistência do material.
- [Android — Auto Backup](https://developer.android.com/identity/data/autobackup): inclui arquivos/preferências e permite configurar exclusões; tratar restauração e transferência ao projetar identidade.

As referências externas sustentam apenas o desenho de lifecycle/backup. Os achados sobre o Zeni derivam do checkout auditado; não houve auditoria de configuração remota nem teste físico de aparelhos.
