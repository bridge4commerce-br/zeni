# Sprint 2B — Proposta de resolução canônica e criação atômica de família

Data: 2026-09-25. Checkout auditado: `40cc056` (`feat: guard cloud sync by family identity`).

Status: proposta para aprovação; nenhuma migration, implementação Flutter ou alteração remota nesta etapa. As queries abaixo são apenas material de diagnóstico, não foram executadas. O working tree estava limpo no início da auditoria.

Referências obrigatórias: [arquitetura v1.0](zeni-multidevice-architecture-v1.0.md) e [contratos da Sprint 2](zeni-multidevice-sprint-2-contratos-e-identidade.md). O segundo documento registra uma auditoria anterior à Sprint 2A; suas descrições do código não substituem a inspeção do checkout atual.

## 1. Comportamento atual e evidências

Definição: [20260528174736_create_remote_identity.sql](../../supabase/migrations/20260528174736_create_remote_identity.sql), linhas 164–229. Permissões posteriores: [hardening](../../supabase/migrations/20260609103000_harden_public_function_execute_permissions.sql).

`ensure_user_family()` não recebe parâmetros, retorna JSONB, usa PL/pgSQL, `SECURITY DEFINER` e `search_path = public, auth`. Sem declaração de volatilidade, é `VOLATILE`. Executa com os privilégios do proprietário da função, cujo papel efetivo deve ser conferido no banco aplicado.

Sequência exata:

1. Obtém `auth.uid()` e email de `auth.jwt()`; UID nulo lança `not_authenticated`.
2. Faz INSERT de `profiles(id, email, display_name)`; conflito na PK atualiza email e updated_at, preservando display_name existente. Portanto até a recuperação de família existente escreve em profile.
3. Consulta membership pelo UID, com JOIN em families, ordena por `fm.created_at ASC` e usa `LIMIT 1`. Não detecta múltiplas memberships; empates não têm desempate explícito. `created_by` não participa da resolução.
4. Se não encontrar membership, insere `families(name='Minha família', created_by=UID)` e depois `family_members(family_id, user_id=UID, role='owner')`.
5. O segundo INSERT usa `ON CONFLICT (family_id,user_id) DO UPDATE role`. Isso não deduplica famílias diferentes.
6. Retorna family_id, family_name, role, user_id e email. Não distingue criada/existente. Erro SQL não tratado aborta a transação, inclusive família recém-inserida.

| Estrutura atual | Garantia | O que não garante |
| --- | --- | --- |
| profiles PK(id) → auth.users | Um profile por usuário | Uma família por usuário |
| families PK(id) UUID; created_by nullable, FK SET NULL | Identidade da família e referência ao criador | Unicidade por criador; existência de owner |
| family_members PK(id), FKs family/user NOT NULL CASCADE | Referências válidas com constraints aplicadas | Uma família por usuário |
| UNIQUE(family_id,user_id) | Mesmo usuário não se repete na mesma família | Usuário pode estar em X e Y |
| CHECK role IN ('owner','responsible') | Vocabulário de papéis | Pelo menos um owner ou apenas um owner |

Não existe coluna de membership ativa/revogada. Hoje toda linha é uma associação atual. Não há índice separado por user_id nas migrations auditadas; a chave composta começa por family_id.

## 2. Concorrência: correção da conclusão anterior

É impreciso dizer que a função atual não é atômica ou que duas chamadas completas necessariamente passam juntas pelo SELECT vazio. A chamada já é uma transação. O upsert inicial de profiles disputa a mesma PK/linha e mantém seu bloqueio até o fim da transação.

Sob `READ COMMITTED`, para duas chamadas da definição versionada:

| Momento | Requisição A | Requisição B |
| --- | --- | --- |
| 1 | Insere/atualiza profile U e mantém lock | Aguarda no upsert do mesmo profile |
| 2 | Consulta membership, cria X e owner U | Continua aguardando |
| 3 | Commit | Completa upsert; SELECT seguinte observa X |
| 4 | Retorna X | Retorna X; não cria Y |

Esta é uma inferência da definição SQL e das regras de [isolamento PostgreSQL](https://www.postgresql.org/docs/current/transaction-iso.html), não um teste executado contra o banco de desenvolvimento. Em isolamento mais forte pode haver erro de serialização, exigindo retry da transação inteira. Não foi verificado qual isolamento/configuração está aplicado remotamente.

O risco estrutural continua real: não há UNIQUE por usuário e outros escritores não precisam passar pelo profile. Exemplo permitido pelas constraints: A consulta ausência de membership de U; B, com permissão de owner de Y, insere U como responsável em Y; A insere X e owner U em X. Ambas as memberships podem persistir. A policy de INSERT direto em families também permite criar X e Y com o mesmo created_by, sem membership, caso o papel tenha o privilégio de tabela correspondente. Um refactor que remova o upsert incidental reabre a corrida clássica SELECT vazio → INSERT X/Y.

Assim, corrigimos a afirmação ampla da seção 3.3 da auditoria da Sprint 2: a proteção atual é incidental ao profile, não ausente. Não há prova de duplicação entre duas chamadas completas da RPC atual no isolamento padrão. A nova solução deve tornar a exclusão explícita, estrutural e independente do profile.

## 3. Contrato de resolução

Nome proposto: `public.resolve_current_family() → jsonb`. Sem argumentos; identidade exclusivamente de `auth.uid()`.

Envelope v1: `contract_version: 1`, `status`, `user_id`, `family` (objeto ou null). Objeto family: `family_id`, `membership_id`, `family_name`, `role`. Não retornar emails nem listas de famílias.

| status | Condição | family |
| --- | --- | --- |
| resolved | Exatamente uma membership, família existente, papel válido e ao menos um owner na família | Objeto canônico |
| no_family | Nenhuma membership para o UID | null |
| ambiguous_membership | Mais de uma membership, sem escolher primeira | null |
| invalid_membership | Única associação com referência/papel inválido, ou família sem owner | null |

UID ausente: erro `not_authenticated`, SQLSTATE `28000`; papel sem EXECUTE pode ser recusado antes de entrar na função. Erro de banco/rede não vira `no_family` nem autoriza create. O cliente deve diferenciar erro técnico e status de domínio.

Resolver não grava profile, family, membership, timestamp de acesso ou reparo. A leitura deve usar um único snapshot de consulta para contar e validar associações. O resultado prova autorização naquele instante; RLS e guard continuam necessários nas operações seguintes. Não exige que o usuário seja owner: responsible é válido. Vários owners são aceitos nesta proposta; ausência de owner bloqueia. `created_by` diferente do owner não invalida membership por si só.

Uma família órfã com created_by=UID não é autorização e não pode ser adotada automaticamente: resolver retorna no_family quando não há membership. Create trata essa anomalia separadamente.

## 4. Contrato de criação explícita

Nome proposto: `public.create_initial_family() → jsonb`. Sem user_id, family_id ou role fornecidos pelo cliente. Nome inicial fixo “Minha família”; edição de nome permanece operação separada existente. Autenticação, por si só, nunca chama esta RPC.

Usa o mesmo envelope e objeto canônico de resolve. Estados:

- `created`: nova família e membership owner foram confirmadas juntas.
- `already_exists`: uma família válida já existe; devolve a mesma família/papel, inclusive responsible, sem promover role nem mudar nome.
- `ambiguous_membership` / `invalid_membership`: bloqueia sem reparar ou criar.
- `recovery_required`: nenhuma membership, mas existe família com created_by=UID; exige diagnóstico controlado. Não adotar, excluir ou criar outra automaticamente.

UID ausente: `not_authenticated`. Falha transacional: erro técnico, nenhuma criação parcial. Timeout/resposta perdida: retry explícito recebe already_exists com a mesma identidade, enquanto a membership existir. A RPC não aceita payload de dados locais e nunca vincula `local-family`.

Idempotência proposta é por estado canônico de usuário, sem nova tabela de recibos/request_id. É suficiente para retries e chamadas simultâneas da configuração inicial, inclusive intenções concorrentes distintas. Não promete replay do mesmo family_id depois de exclusão deliberada da família/conta. O cliente descarta tentativas pendentes ao trocar sessão ou encerrar o fluxo. A proposta anterior mencionava chave de solicitação; dispensá-la nesta fase é uma simplificação que precisa de aprovação. Se for necessário replay durável mesmo após exclusão, será preciso contrato adicional de lifecycle/recibos antes do SQL.

## 5. Atomicidade e constraint recomendadas

Recomendação: UNIQUE não deferrable `family_members(user_id)` + função transacional com advisory lock de transação por UID. Preservar UNIQUE(family_id,user_id), PKs e FKs. Não criar UNIQUE(family_id) nem UNIQUE apenas para owners: o primeiro impediria múltiplos responsáveis; o segundo permitiria ambiguidade entre memberships responsible.

A nova constraint limita cada responsável a uma membership no schema V1, mas permite muitos user_ids na mesma family_id. É mais restritiva que apenas “uma família ativa”: sem lifecycle de memberships no schema atual, é a menor implementação. Para evolução multi-família, substituí-la futuramente por contrato explícito de família ativa. Essa escolha precisa de aprovação; não é uma limitação permanente da arquitetura.

O índice UNIQUE por user_id já atende à resolução; não criar outro índice idêntico. Nenhuma constraint em families.created_by é necessária: criador não é proprietário atual, o campo aceita null e sua unicidade não impede usuário de participar de família criada por outra pessoa.

Algoritmo previsto, sem implementação nesta etapa:

1. Capturar e validar UID.
2. Adquirir `pg_advisory_xact_lock` usando chave bigint derivada no backend de namespace fixo `zeni:create_initial_family:v1:` + UID, por `pg_catalog.hashtextextended(..., 0)`. Nunca aceitar a chave do cliente. Colisão de hash apenas serializa usuários extras; não mistura identidade.
3. Só depois do lock, resolver novamente todas as memberships do UID; tratar os estados da seção 4.
4. Sem membership, verificar família atribuída ao criador para detectar anomalia; se houver, retornar recovery_required.
5. Preparar profile quando necessário (somente no caminho create), criar family e owner na mesma transação.
6. Deixar qualquer erro de constraint abortar todas as escritas. Não capturar erro da membership e retornar sucesso mantendo a família inserida.
7. Retornar created após conclusão transacional da RPC.

A pega lock, B espera; A cria X e confirma; B adquire lock, reconsulta e retorna X. Se A falhar, suas escritas são revertidas e B pode criar a única família. Em READ COMMITTED a reconsulta deve ser uma instrução posterior ao lock numa função VOLATILE. Em snapshot antigo/erro de serialização, repetir a transação inteira; não continuar com a leitura antiga.

UNIQUE é a defesa contra escritores que não cooperam com advisory lock. Uma colisão externa pode fazer create falhar, mas a transação inteira reverte sua família provisória; retry re-resolve. Mudanças administrativas futuras de membership devem respeitar o mesmo protocolo. Locks de transação são liberados ao commit/rollback: [documentação PostgreSQL](https://www.postgresql.org/docs/current/explicit-locking.html).

Alternativas: apenas transação não protege SELECT vazio; apenas advisory lock depende de todos os escritores; apenas UNIQUE é seguro contra duplicidade se todo o INSERT de família reverter, mas a segunda chamada normalmente falha; ON CONFLICT(user_id) não deve reassociar usuário à família perdedora nem deixar família órfã; SERIALIZABLE exige retry geral sem substituir a constraint. Lock em auth.users também funcionaria, mas acopla o fluxo ao bloqueio de registros de Auth; advisory lock evita esse acoplamento e não requer tabela nova.

## 6. Segurança e fechamento de caminhos alternativos

Hoje RLS está habilitada, sem FORCE RLS nas migrations. SELECT de families e family_members depende de `is_family_member`; UPDATE de família permite owner/responsible. INSERT de família exige created_by=auth.uid(). Owner pode inserir, atualizar e excluir memberships; não há proteção do último owner nem imutabilidade dos IDs.

Hardening versionado revoga EXECUTE da RPC antiga de PUBLIC/anon e concede authenticated. Não há revogação explícita de service_role para ensure; default privileges e herança não estão completamente descritos pelas migrations. Não afirmar permissões efetivas desse papel sem diagnóstico. BYPASSRLS não equivale a possuir EXECUTE. A RPC de exclusão é separada e fica exclusiva de service_role após hardening; preservá-la.

Para as duas RPCs novas, propor SECURITY DEFINER, dono confiável com privilégios mínimos viáveis, `search_path = ''`, referências qualificadas `public.*`, `auth.*`, `pg_catalog.*`, sem SQL dinâmico. Resolve precisa enxergar anomalias sem depender de RLS que esconda linhas; seu corpo filtra exclusivamente o UID e contém apenas consultas. Create é VOLATILE. Auditoria deve verificar dono, ACL e corpo: [orientação PostgreSQL sobre funções](https://www.postgresql.org/docs/current/sql-createfunction.html).

Na mesma transação de publicação, revogar EXECUTE de PUBLIC, anon e service_role nas novas assinaturas; conceder somente authenticated. Owner/admin de banco continua privilegiado. Auth.uid nulo sempre falha. Não aceitar identidade de terceiros nem confiar no owner local do Flutter.

Proposta de fechamento V1, sujeita a aprovação: remover policy INSERT direto de families e revogar INSERT de PUBLIC/anon/authenticated; revogar INSERT/UPDATE/DELETE diretos de family_members desses papéis e retirar suas policies de escrita. Manter SELECT/RLS, UPDATE autorizado de nome de família e suporte estrutural a vários responsáveis. A UI atual não implementa gestão de memberships; convites/transferência terão RPC própria no futuro. Isso também impede demover/excluir último owner pelo cliente. Revogar privilégios herdados efetivos, não apenas a concessão direta; conferir ACLs de coluna. Service_role permanece administrativo, nunca usado no Flutter, e seus caminhos de manutenção precisam de disciplina transacional.

Excluir conta Auth por administração ainda pode deixar família sem owner por CASCADE; a resolução bloqueia a anomalia. Não alegar que a proposta cria uma constraint global “sempre há owner”. Não alterar nesta etapa o fluxo de exclusão nem implementar gestão de owners.

## 7. Impacto previsto no Flutter e compatibilidade

| Caminho | Estado atual pós-2A | Mudança futura necessária |
| --- | --- | --- |
| Login e signup autenticado por email/Google/Apple | `_ensureRemoteFamilyIfNeeded` consulta remoto e ainda chama ensure em base vazia/segura | Autenticar e resolver apenas; remover chamada automática a create/ensure |
| Recuperação de sessão | Stream atualiza auth state | Resolver sem criar; tratar no_family/ambiguidade/erro separadamente |
| Repository/account providers | Summary nullable; limit(2); null reúne ausência, ambiguidade e falha | Resultado tipado para estados explícitos; provider de summary pode adaptar somente resolved |
| Criar minha família | Ainda não existe contrato remoto explícito separado | Comando dedicado, por intenção do usuário, base local segura e sessão revalidada |
| Já uso o Zeni | Autenticação compartilhada ainda pode assegurar família vazia | Resolver apenas; no_family não aciona create |
| Guard, sync manual e por domínio | Comparação de família/grafo e revalidações da Sprint 2A | Preservar integralmente; resolver remoto não autoriza reassociar base local |
| Bootstrap/restore | Base segura + família compatível + catálogos/histórico | Consumir família resolvida; nenhum fallback de criação |

Fontes: [auth providers](../../lib/features/auth/presentation/providers/zeni_auth_providers.dart), [account repository](../../lib/features/auth/data/repositories/supabase_account_repository.dart), [account providers](../../lib/features/auth/presentation/providers/zeni_account_providers.dart), [guard](../../lib/features/sync/presentation/providers/family_identity_guard.dart), [sync](../../lib/features/sync/presentation/providers/cloud_sync_providers.dart), [bootstrap](../../lib/features/sync/presentation/providers/device_bootstrap_providers.dart), [restore](../../lib/features/sync/presentation/providers/historical_restore_providers.dart).

Há um ponto de integração obrigatório: bootstrap atual recusa catálogo remoto vazio. Uma família recém-criada estará vazia; o futuro comando explícito de criação precisará persistir identidade canônica em base comprovadamente vazia/segura, com revalidação da sessão e durabilidade, antes de permitir cadastro local. Não usar o bootstrap de recuperação como gambiarra nem relaxar seu guard. Recuperar família existente vazia deve produzir estado explícito de configuração incompleta, sem criar outra. Esse trabalho será especificado/implementado no Flutter em etapa autorizada, não aqui.

A remoção de ensure interrompe builds antigos que dependem dele. Como pré-lançamento, recomendar janela coordenada e retirar esses builds de uso; não manter um adapter antigo que ainda possa criar. Publicar apenas funções novas e manter ensure ativo não conclui a 2B. Não mudar ledger, saldo, child_id, devices, pairing, sync V2 ou mecanismos de restore.

## 8. Diagnóstico pré-migration — somente consultas propostas

Executar futuramente em ambiente administrativo autorizado, em transação READ ONLY para snapshot consistente. Nenhuma query abaixo foi executada; não sabemos se o banco de desenvolvimento contém anomalias. Não selecionar emails/tokens. Não converter resultados automaticamente em DELETE/UPDATE.

```sql
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;

-- Ambiente e isolamento efetivos.
SELECT version(), current_setting('transaction_isolation');

-- Inventário: usuários com zero, uma e múltiplas memberships.
SELECT u.id AS user_id, count(fm.id) AS membership_count,
       array_agg(fm.family_id) FILTER (WHERE fm.id IS NOT NULL) AS family_ids
FROM auth.users u
LEFT JOIN public.family_members fm ON fm.user_id = u.id
GROUP BY u.id
ORDER BY membership_count DESC, u.id;

-- Duplicações e famílias repetidas por criador.
SELECT family_id, user_id, count(*)
FROM public.family_members GROUP BY family_id, user_id HAVING count(*) > 1;
SELECT created_by, count(*), array_agg(id) AS family_ids
FROM public.families WHERE created_by IS NOT NULL
GROUP BY created_by HAVING count(*) > 1;

-- Famílias sem membros, sem owner ou com múltiplos owners (revisão, não erro automático).
SELECT f.id, f.created_by, count(fm.id) AS members,
       count(fm.id) FILTER (WHERE fm.role = 'owner') AS owners
FROM public.families f
LEFT JOIN public.family_members fm ON fm.family_id = f.id
GROUP BY f.id, f.created_by
HAVING count(fm.id) = 0
    OR count(fm.id) FILTER (WHERE fm.role = 'owner') <> 1;

-- Criador sem membership correspondente: não adotar implicitamente.
SELECT f.id, f.created_by
FROM public.families f
LEFT JOIN public.family_members fm
  ON fm.family_id = f.id AND fm.user_id = f.created_by
WHERE f.created_by IS NULL OR fm.id IS NULL;

-- Referências/papéis inválidos se houver drift ou constraints não validadas.
SELECT fm.id, fm.family_id, fm.user_id, fm.role
FROM public.family_members fm
LEFT JOIN public.families f ON f.id = fm.family_id
LEFT JOIN auth.users u ON u.id = fm.user_id
WHERE f.id IS NULL OR u.id IS NULL OR fm.role IS NULL
   OR fm.role NOT IN ('owner', 'responsible');

-- Constraints e índices realmente aplicados.
SELECT conrelid::regclass AS relation, conname, contype, convalidated,
       pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid IN ('public.families'::regclass, 'public.family_members'::regclass,
                  'public.profiles'::regclass);
SELECT tablename, indexname, indexdef FROM pg_indexes
WHERE schemaname = 'public' AND tablename IN ('families','family_members','profiles');

-- RLS, owners e permissões das tabelas.
SELECT oid::regclass AS relation, pg_get_userbyid(relowner) AS owner,
       relrowsecurity, relforcerowsecurity, relacl
FROM pg_class WHERE oid IN ('public.families'::regclass,
                           'public.family_members'::regclass,
                           'public.profiles'::regclass);
SELECT * FROM pg_policies
WHERE schemaname = 'public' AND tablename IN ('families','family_members','profiles');
SELECT grantee, table_name, privilege_type FROM information_schema.table_privileges
WHERE table_schema = 'public' AND table_name IN ('families','family_members','profiles');
SELECT grantee, table_name, column_name, privilege_type
FROM information_schema.column_privileges
WHERE table_schema = 'public' AND table_name IN ('families','family_members');

-- Todas as funções públicas: localizar overloads, definer e outros escritores.
SELECT p.oid::regprocedure AS signature, pg_get_userbyid(p.proowner) AS owner,
       p.prosecdef, p.provolatile, p.proconfig, p.proacl,
       pg_get_functiondef(p.oid) AS definition
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.prokind = 'f';

-- Grants efetivos e papéis: BYPASSRLS não substitui EXECUTE.
SELECT r.rolname, r.rolsuper, r.rolbypassrls, r.rolinherit,
       has_function_privilege(r.oid, 'public.ensure_user_family()', 'EXECUTE') AS can_ensure,
       has_table_privilege(r.oid, 'public.families', 'INSERT') AS can_insert_family,
       has_table_privilege(r.oid, 'public.family_members', 'INSERT') AS can_insert_member,
       has_schema_privilege(r.oid, 'public', 'CREATE') AS can_create_in_public
FROM pg_roles r WHERE r.rolname IN ('anon','authenticated','service_role');
SELECT roleid::regrole, member::regrole, admin_option FROM pg_auth_members;
SELECT defaclrole::regrole, defaclnamespace::regnamespace,
       defaclobjtype, defaclacl FROM pg_default_acl;

-- Triggers que possam adicionar efeitos não documentados.
SELECT tgrelid::regclass, tgname, pg_get_triggerdef(oid)
FROM pg_trigger WHERE NOT tgisinternal
  AND tgrelid IN ('public.profiles'::regclass, 'public.families'::regclass,
                 'public.family_members'::regclass, 'auth.users'::regclass);
COMMIT;
```

Se houver usuários multi-família, suspender a aplicação de UNIQUE e decidir cada caso com inventário dos dados dependentes. Não escolher menor created_at, fundir famílias, apagar filhos ou promover owners automaticamente. Usuário sem família é estado normal; não requer backfill. Família sem owner/orfandade requer correção controlada e aprovada. Nenhuma migração genérica de legado local é proposta.

## 9. Migration futura e ordem de implantação

1. Aprovar decisões da seção 12; executar e revisar diagnósticos sob autorização futura; confirmar schema, roles, default privileges e versão/isolation do ambiente.
2. Preparar testes PostgreSQL de integração e plano de atualização dos clientes. Fazer backup e inventário de DDL/ACL aplicados antes de qualquer alteração.
3. Resolver somente anomalias previamente aprovadas; não embutir backfill destrutivo na migration.
4. Em janela controlada, impedir escritores de identidade concorrentes; abrir transação DDL, adquirir locks necessários, repetir checagens antes de adicionar UNIQUE(user_id). Em base pequena pré-lançamento preferir constraint normal transacional; se volume inviabilizar lock, redesenhar implantação do índice antes de executar.
5. Criar as duas funções com assinaturas/estados descritos; definir owner/search_path/ACL na mesma transação para não expor EXECUTE público temporariamente.
6. Fechar INSERT direto de família e DML de memberships conforme seção 6. Preservar RLS de leitura, edição de nome e RPC de exclusão existente.
7. Aposentar ensure_user_family: revogar todos os acessos de aplicação, PUBLIC/anon/authenticated/service_role, incluindo overloads encontrados; remover a função sem CASCADE após verificar dependências. Nenhum alias de ensure poderá continuar criando.
8. Validar constraints/ACLs e confirmar transação. Recarregar schema cache da API se necessário no procedimento de deploy. Liberar apenas cliente compatível; nenhum período operacional deve depender da RPC removida.
9. Verificar login só resolve, criação explícita, família vazia, guard, bootstrap e restore em ambiente de teste antes de liberar beta.

Não há DDL implementado neste documento. O plano pressupõe coordenação com a futura mudança Flutter: criar o arquivo SQL pode ser a próxima etapa, aplicá-lo isoladamente sobre clientes atuais não é seguro.

## 10. Testes exigidos antes da aplicação

| Cenário | Resultado e evidência |
| --- | --- |
| Resolve com owner e com responsible | Mesma identidade canônica; nenhum papel promovido |
| Resolve sem membership | no_family; contagens e timestamps de todas as tabelas iguais |
| Resolve repetido em transação READ ONLY | Sucesso de leitura; nenhum profile criado ou atualizado |
| Create sem família | Uma family + owner, UID derivado de Auth; created |
| Create repetido/resposta perdida | already_exists, mesmo family_id; nenhum novo profile effect indevido ou família |
| Duas creates concorrentes do mesmo UID | Duas conexões/transações reais e barreira de execução; uma criada, outra existente, mesma família, uma membership |
| Create simultâneo de U e V | Famílias independentes; nenhuma identidade cruzada |
| Falha entre INSERT family e membership | Rollback total, sem família órfã |
| Escritor não cooperante colide em user_id | UNIQUE impede duplicidade; criação provisória reverte |
| Conta A versus B / payload forjado | Resolve A nunca retorna B; argumentos user_id/role/family_id não existem |
| anon/PUBLIC/service_role sem grant e UID nulo | Negado; autenticado não consegue usar UID de outra pessoa |
| Ambiguidade/role inválido/FK quebrada | Fixtures isoladas pré-constraint/drift; estado explícito, sem LIMIT 1 ou reparo |
| Família sem owner; created_by sem membership | invalid_membership ou recovery_required conforme contrato; sem associação silenciosa |
| Vários responsáveis/owners na mesma família | Permitido para user_ids diferentes; cada usuário resolve sua mesma família |
| INSERT direto de família, mudança/exclusão de membership | Negado para cliente; edição autorizada do nome continua válida |
| Login/signup/OAuth/recuperação/refresh/sync manual | Zero chamadas a create, inclusive com base vazia e no_family |
| Base unbound com dados, mismatch A/B, logout ou resposta tardia | Preservar integralmente os testes e bloqueios da Sprint 2A |
| Criar em base vazia | Persistir identidade canônica antes de conteúdo; sessão trocada bloqueia aplicação |
| Já uso o Zeni com família existente | Bootstrap seguro e histórico separado funcionam; no_family/vazia não criam outra família |
| Erro de rede, timeout, deadlock/serialização | Nunca interpretado como no_family; retry da operação inteira quando aplicável |

Os testes atuais em cloud_manual_sync_test.dart cobrem guard/grafo/mismatch e três caminhos de login. O cenário “login may ensure a remote family for an empty safe base” deve mudar para zero criação automática e ganhar teste separado de intenção explícita. account_data_test.dart deve separar falha de login de falha de criação. Preservar cobertura de auth_test.dart, device_bootstrap_test.dart, first_access_restore_test.dart e historical_restore_test.dart. Fakes Dart não comprovam RLS, ACLs ou concorrência PostgreSQL.

## 11. Riscos e rollback

Riscos: dados de desenvolvimento bloqueando UNIQUE; cliente antigo quebrado pela retirada de ensure; default grants/overloads mantendo bypass; ausência de persistência canônica no novo fluxo vazio; manutenção administrativa que ignore locks; snapshots/retries após exclusão deliberada. Múltiplos owners não são proibidos; gestão do último owner e convites são evolução própria.

Antes de commit da migration, falha reverte DDL e funções transacionais. Depois da implantação, preferir rollback do fluxo de criação (revogar create e manter resolve/constraints/guard), preservando famílias já criadas e dados. Não apagar famílias para “desfazer” a release. Reverter UNIQUE/policies requer nova avaliação de dados/segurança e não deve reabrir ensure com criação implícita. Build Flutter antigo não é rollback compatível: precisa de versão corretiva que continue usando resolução sem criação automática. Guard da Sprint 2A permanece em todos os casos.

## 12. Decisões para aprovação e prontidão

É seguro preparar uma migration na próxima etapa após aprovação destas escolhas; não é seguro aplicar SQL ainda, pois o banco real não foi diagnosticado e o cliente atual chama ensure.

Decisões propostas que exigem aceite antes do SQL:

1. UNIQUE(user_id) em family_members como restrição reversível da V1, preservando múltiplos responsáveis por família.
2. Duas RPCs sem parâmetros; nome inicial fixo; retorno de família existente sem promoção de papel; idempotência por estado, sem recibo/request_id nesta fase.
3. Advisory lock transacional + UNIQUE; erro concorrente externo reverte tudo e exige re-resolução/retry.
4. Família sem owner bloqueia; múltiplos owners são válidos; família do criador sem membership exige recuperação explícita.
5. Fechar DML direto de memberships e INSERT direto de família; retirar ensure em janela coordenada com cliente compatível.

Nenhuma divergência com a proteção da Sprint 2A. As duas especializações da proposta anterior que precisam de decisão são a restrição temporária por user_id e a dispensa da chave de solicitação. Nenhum dado de desenvolvimento será corrigido sem diagnóstico e autorização específicos.
