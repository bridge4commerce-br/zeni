# Zeni — Arquitetura Multi-dispositivo v1.0

Status: decisões arquiteturais consolidadas da Sprint 1

Escopo: análise e decisões de arquitetura; sem implementação

Última atualização: 2026-09-25

## 1. Estado atual

O Zeni possui uma base offline-first em que o estado operacional é mantido localmente pelo `ZeniAppStateController` e persistido como um estado agregado em `SharedPreferences`. Esse estado reúne família, crianças, membros, missões, logs de missão, mimos, pedidos, ledger e configurações locais.

A autenticação atual é opcional. O estado inicial cria uma família e um responsável locais antes do login. Depois de uma autenticação válida, `ensure_user_family()` cria ou recupera uma família remota vinculada ao usuário autenticado.

O sync atual opera por domínio, em sequência:

1. crianças;
2. missões;
3. mimos;
4. logs de missão;
5. pedidos de mimo;
6. ledger de estrelas;
7. pull e aplicação de snapshots remotos.

O app já cria oportunidades de sync após alterações relevantes, no retorno ao foreground e por ação manual. Há debounce e proteção contra execuções simultâneas no mesmo processo, mas não existe ainda:

- identidade persistente de instalação;
- vínculo de aparelho infantil;
- outbox durável;
- cursor de mudanças por aparelho;
- revisão-base para conflitos;
- protocolo completo de colaboração multi-dispositivo.

As restaurações atuais são separadas em:

- bootstrap de aparelho novo, com família, crianças, missões e mimos;
- restauração histórica, com logs, pedidos e ledger.

O histórico recompõe `balanceAfter` e `ChildProfile.starBalance` a partir do ledger. `child_star_balances` funciona somente como conferência. `streak` não é restaurado.

## 2. Gaps para multi-dispositivo

### 2.1 Família criada antes da autenticação

O app atual cria `local-family` antes do login. Isso conflita com a nova premissa de que a criação inicial de uma família exige conta do responsável e conectividade.

Como o Zeni ainda não foi lançado publicamente com a arquitetura anterior, a V1 não terá uma migração genérica de famílias locais legadas. Uma família local nunca pode ser associada silenciosamente à primeira conta autenticada, pois isso pode vincular dados à família errada. O novo fluxo multi-dispositivo começa com identidade canônica criada ou autorizada; dados de desenvolvimento e beta podem receber tratamento controlado durante a transição.

### 2.2 Ausência de identidade de aparelho

Não há `device_id`, `device_link_id`, chave criptográfica da instalação ou revogação por aparelho. Nome, modelo ou identificador de hardware não devem ser usados como identidade.

### 2.3 Ausência de autorização infantil

As políticas remotas atuais são baseadas em usuários autenticados pertencentes à família e, para escrita, em papéis de responsável. Não existe uma credencial limitada a uma criança e a um aparelho.

### 2.4 Sync orientado a snapshots

O sync atual busca por `local_id`, faz insert/update remoto e depois aplica snapshots. Ele não mantém outbox e cursor duráveis e não distingue adequadamente alterações confirmadas, pendentes e conflitantes.

### 2.5 Entidades sem revisão-base

Crianças, missões e mimos não possuem revisão usada em atualização condicional. Duas edições offline podem sobrescrever uma à outra.

### 2.6 Ledger ainda não estritamente append-only

O banco possui `idempotency_key`, mas a implementação atual pode atualizar uma entrada já existente, e a RLS permite `UPDATE`. Na arquitetura final, ledger deve ser append-only e criado apenas por transições de domínio validadas ou ajustes autorizados.

### 2.7 Persistência local sem transação entre estado e outbox

Um JSON agregado em `SharedPreferences` não oferece a atomicidade necessária para gravar, em uma única transação durável, a alteração operacional, a operação da outbox e seus metadados de sync.

## 3. Modelo de identidade

A conta identifica uma pessoa responsável. Ela não é o próprio identificador da família, pois uma família poderá possuir mais de um responsável.

| Identificador | Responsabilidade | Ciclo de vida |
| --- | --- | --- |
| `auth.user_id` | Identidade remota do responsável | Permanente enquanto a conta existir; não é compartilhado com a criança |
| `family_id` | Identidade canônica remota da família | Criado online na configuração inicial; sincronizado e estável entre aparelhos |
| `child_id` | Identidade canônica remota da criança | Estável entre aparelhos; não é segredo |
| `device_id` | Identidade aleatória de uma instalação | Local e registrada remotamente; nova após reinstalação efetivamente nova |
| `device_link_id` | Vínculo entre aparelho e responsável ou criança | Remoto, persistido localmente e revogável |
| `pairing_id` | Identidade de uma tentativa de pareamento | Temporária, expirável, cancelável e consumível uma única vez |
| código/segredo de pareamento | Credencial temporária de resgate | Nunca é `family_id` ou `child_id`; não permanece utilizável após consumo |

Para múltiplos responsáveis, a autorização deriva de `family_members(family_id, user_id, role)`. Na V1, um responsável trabalha com uma única família ativa. Não haverá seletor de famílias nem cache simultâneo de várias famílias. A estrutura de memberships pode permanecer preparada para uma evolução futura, mas essa capacidade não será exposta nesta versão.

Um mesmo `child_id` pode possuir mais de um `device_link_id` ativo. Não deve existir restrição estrutural que limite uma criança a um único aparelho.

Em bases de desenvolvimento ou beta que recebam tratamento controlado, IDs locais existentes podem servir como chaves de correspondência, mas nunca como base implícita de identidade entre instalações.

## 4. Modelo de device

Cada instalação cria:

- `device_id` aleatório;
- par de chaves criptográficas no armazenamento seguro do sistema;
- marcador local da instalação;
- registro remoto apenas da chave pública e metadados necessários.

O servidor emite credenciais limitadas ao vínculo e exige prova de posse da chave para renovação. O nome do aparelho pode existir apenas como descrição para o responsável.

### 4.1 Parent device

- requer sessão de autenticação válida para operações remotas administrativas;
- usa `device_link_id` para auditoria e controle de aparelhos, não para substituir o login;
- PIN e biometria continuam como proteções locais;
- logout remove a sessão, preserva dados locais e não revoga automaticamente aparelhos infantis.

### 4.2 Child device

- não possui login, e-mail ou senha;
- recebe credencial própria vinculada a exatamente uma família e uma criança;
- cada aparelho possui seu próprio `device_id`, `device_link_id`, credencial e estado de revogação;
- uma criança pode manter simultaneamente dois ou mais vínculos de aparelho ativos;
- só acessa o subconjunto autorizado dessa criança;
- reinstalação cria nova identidade e exige novo pareamento;
- não recebe sessão do responsável nem chave de serviço.

### 4.3 Revogação e aparelho perdido

Revogar um `device_link_id` bloqueia novas leituras, uploads e renovações quando aquele aparelho se comunica novamente com o servidor. A revogação de um vínculo não revoga os demais aparelhos da mesma criança. A revogação não consegue apagar imediatamente dados já armazenados em um aparelho desconectado. Esse limite deve ser comunicado e complementado pela validade offline de 48 horas definida na seção 10.

## 5. Modelo de pairing

Fluxo canônico:

1. o responsável autenticado escolhe a criança;
2. solicita “Vincular aparelho”;
3. o backend cria `pairing_id` já ligado a `family_id` e `child_id`;
4. o backend entrega um código legível e/ou QR;
5. o aparelho infantil cria sua identidade de instalação;
6. o aparelho resgata o segredo e prova posse de sua chave;
7. o backend valida escopo, expiração, cancelamento e tentativas;
8. na mesma transação, cria `device_link_id` e consome o pareamento;
9. o aparelho recebe sua credencial limitada.

O código digitável deve ter entropia adequada e evitar caracteres ambíguos. Uma referência inicial razoável é 12 caracteres de um alfabeto reduzido. A validade inicial do pareamento é de 10 minutos, contados conforme a política emitida pelo backend.

Código e QR representam o mesmo `pairing_id`, expiram juntos e são duas formas de resgatar a mesma tentativa. O pareamento é single-use: consumir o código invalida o QR, e consumir o QR invalida o código. O responsável pode cancelar um pareamento ainda não consumido.

O prazo de 10 minutos deve ser configurável no backend e fornecido como parte do contrato do pareamento. A aplicação não deve espalhar nem fixar essa constante em diferentes pontos do Flutter.

O backend deve:

- gerar o segredo com fonte criptograficamente segura;
- guardar apenas digest com HMAC e segredo do servidor;
- nunca registrar o código em logs ou analytics;
- impor unicidade entre pareamentos ativos;
- limitar tentativas por origem, instalação e família;
- usar respostas uniformes para reduzir enumeração;
- consumir o pareamento com operação condicional e bloqueio de linha;
- impedir por restrição/transação que a mesma credencial crie dois vínculos.

`Family.inviteCode`, inclusive valores locais legados como `ZENI00`, não pode ser reutilizado como credencial de pareamento.

## 6. Modelo de sync V2

Fluxo canônico:

`alteração local → estado local + outbox em uma transação → upload idempotente → commit remoto → ACK → pull por cursor → aplicação local transacional → avanço do cursor`

### 6.1 Outbox

Cada operação sincronizável registra de forma durável:

- `operation_id` estável;
- `device_id`;
- `family_id` e escopo autorizado;
- domínio e entidade;
- tipo de comando;
- revisão-base, quando aplicável;
- payload e dependências;
- data local apenas para exibição/auditoria;
- status, tentativas e último erro.

Retry reutiliza o mesmo `operation_id`. Repetir a mesma chave e payload retorna o resultado anterior. Reutilizar a chave com payload diferente é erro.

Uma ação que depende da nuvem ou de outro aparelho não pode ser apresentada como enviada antes do ACK do servidor. Os estados conceituais da experiência são:

- **salvo neste aparelho / aguardando conexão**: persistido localmente, ainda sem ACK;
- **enviado**: aceito pelo servidor e confirmado por ACK;
- **aguardando aprovação**: recebido pelo fluxo remoto e dependente de decisão do responsável;
- **aprovado**: decisão remota favorável confirmada;
- **rejeitado**: decisão remota desfavorável confirmada.

Missões automáticas continuam obedecendo às suas regras específicas. Missões que exigem aprovação e pedidos de mimo podem ser criados offline, mas só são considerados recebidos pelo fluxo remoto após ACK. Antes disso, a interface deve comunicar apenas que a ação foi salva no aparelho.

Preferências puramente locais — inclusive aparência por perfil + aparelho, PIN e biometria — não entram na outbox e não afetam cursor ou checkpoint do sync multi-dispositivo.

### 6.2 Pull e cursor

O servidor atribui revisão ou sequência monotônica ao feed de mudanças. O aparelho busca mudanças posteriores ao cursor confirmado. O cursor só avança depois que todas as mudanças do lote forem aplicadas localmente com sucesso.

Relógios dos aparelhos não decidem precedência. Timestamps do cliente podem ser preservados como informação contextual, mas ordenação e conflito dependem de revisão e sequência do servidor.

Exclusões sincronizadas usam tombstones/arquivamento com retenção inicial de 90 dias. O cursor/checkpoint possui validade inicial de 30 dias. Os dois prazos devem ser configuráveis no backend; não são constantes de produto espalhadas pelo cliente.

Quando um aparelho retorna com cursor/checkpoint inválido, não tenta continuar um feed potencialmente incompleto. Ele deve:

1. preservar a outbox local ainda não confirmada;
2. obter um snapshot consistente do servidor;
3. reconciliar as operações locais pendentes conforme as regras desta arquitetura, antes de sobrescrever estado relacionado;
4. aplicar snapshot e reconciliação de forma transacional;
5. receber e persistir um novo cursor/checkpoint correspondente ao estado consistente.

Ausência em snapshot não equivale automaticamente a exclusão, e o snapshot nunca pode apagar silenciosamente operações locais pendentes.

### 6.3 Oportunidades de sync

- abertura do app;
- retorno ao foreground;
- retorno da conectividade;
- alteração local sincronizável;
- debounce curto após alterações sucessivas;
- pull-to-refresh ou “Sincronizar agora”.

Falhas usam retry com backoff e jitter. Não há polling periódico recorrente como mecanismo principal. A proteção `single-flight` atual pode ser reaproveitada em memória, mas não substitui a outbox durável.

### 6.4 Pedido de mimo offline e saldo

Um pedido de mimo pode ser criado offline. Enquanto não houver ACK, seu estado local é **salvo neste aparelho / aguardando conexão**: ele não deve ser apresentado como definitivamente recebido e não produz débito definitivo no ledger.

Na sincronização, o servidor:

1. valida o vínculo do aparelho, o mimo (`reward`), o custo e o estado do pedido;
2. serializa a decisão por `child_id`;
3. verifica o saldo confirmado aplicável, sem tratar o saldo enviado pelo cliente como autoridade;
4. se o pedido for válido e houver saldo, aceita-o e produz o efeito financeiro uma única vez;
5. se o saldo for insuficiente, rejeita-o com motivo explícito, como `insufficient_balance`.

Em pedidos concorrentes originados de aparelhos diferentes, a decisão serializada pode aceitar um pedido e rejeitar o outro. O cliente rejeitado deve receber e persistir o estado confirmado, o motivo da rejeição e o saldo confirmado resultante para reconciliar sua projeção e apresentar feedback explícito. A reconciliação nunca substitui silenciosamente o saldo local nem oculta o conflito.

## 7. Classificação por domínio

| Domínio | Classificação | Estratégia |
| --- | --- | --- |
| `FAMILY` | Entidade administrativa versionada | Alterações por responsável autorizado, revisão-base e auditoria |
| `FAMILY_MEMBERS` | Associação administrativa versionada | Papéis e convites protegidos; suporte futuro a múltiplos responsáveis |
| `CHILDREN` | Entidade administrativa versionada | Edição condicional; arquivamento sem apagar histórico; saldo fora do perfil remoto editável |
| `MISSIONS` | Catálogo versionado | Revisão-base, conflito explícito e tombstone/arquivamento |
| `REWARDS` | Catálogo versionado | Revisão-base, conflito explícito e tombstone/arquivamento |
| `MISSION_LOGS` | Projeção de comandos/transições | Conclusão, cancelamento, aprovação, rejeição e desfazer validados pelo servidor |
| `REWARD_REQUESTS` | Projeção de comandos/transições | Pedido e decisão idempotentes; custo validado/capturado pelo backend |
| `STAR_LEDGER_ENTRIES` | Eventos append-only | Criados uma vez por transições aceitas ou ajustes autorizados |
| `ChildProfile.starBalance` | Projeção operacional local | Continua dirigindo a UX; recomposto por eventos e nunca substituído cegamente pela view remota |
| `child_star_balances` | Dado derivado remoto | Conferência e diagnóstico; não é fonte operacional da UX |
| aparência por perfil + aparelho | Dado exclusivamente local | Tema, escala e OpenDyslexic sem sync, outbox, cursor, revisão ou conflito remoto |
| segurança e sessão | Dado exclusivamente local | PIN, biometria, sessão e segredos permanecem no aparelho |
| demais preferências puramente locais | Dado exclusivamente local | Não sincronizar; defaults do Zeni em aparelho novo |

### 7.1 Unicidade de negócio do ledger

`operation_id` é a chave de idempotência de transporte e retry. Ela não é suficiente para impedir que aparelhos diferentes criem operações distintas para o mesmo efeito financeiro.

Todo efeito do ledger deve possuir uma `business_effect_key` estável, derivada da causa canônica do efeito. Exemplos conceituais:

- `mission_log:<id>:approval_credit`;
- `reward_request:<id>:debit`;
- `manual_adjustment:<id>`;
- `ledger_entry:<id>:reversal`.

A mesma causa de negócio só pode produzir um efeito financeiro equivalente. A unicidade da `business_effect_key` deve ser garantida no servidor/banco, e a chave deve ser preferencialmente construída pelo backend ou validada contra a entidade e a transição canônicas. O servidor não confia em uma string arbitrária enviada pelo cliente.

Retries podem repetir o mesmo `operation_id`. Operações concorrentes com `operation_id` diferentes ainda são deduplicadas pela `business_effect_key`. Os detalhes físicos de coluna, índice ou constraint ficam para a sprint de implementação do ledger e não fazem parte desta consolidação arquitetural.

### 7.2 Preferências de aparência e acessibilidade

Tema, tamanho da letra e OpenDyslexic pertencem à combinação **perfil + aparelho**, e não a uma preferência global da criança.

Exemplo em um iPad compartilhado:

- responsável: automático, 100%, fonte normal;
- criança A: escuro, 115%, OpenDyslexic;
- criança B: claro, 100%, fonte normal.

O aparelho próprio da criança A pode manter outra configuração independente.

Consequências arquiteturais e de produto:

- o responsável pode configurar a aparência da criança naquele aparelho;
- a criança pode alterar sua própria aparência naquele aparelho;
- a criança não acessa Settings do responsável;
- o modo criança possui somente uma área limitada de aparência/acessibilidade;
- alterações não se propagam para outros aparelhos;
- aparelho novo começa com os defaults do Zeni;
- não existe conflito, versionamento ou sync dessas preferências;
- esses dados não entram na outbox nem são representados no cursor.

O armazenamento local deve indexar essas preferências por um escopo equivalente a `(local_device_installation, profile_scope)`, incluindo um escopo próprio para o responsável. Isso é uma decisão de persistência local, não um novo domínio remoto.

## 8. Conflitos e resolução

Não existe merge genérico nem política global de last-write-wins.

| Conflito | Autoridade e resolução |
| --- | --- |
| Dois responsáveis editam a mesma missão offline | Servidor aceita a primeira operação baseada na revisão vigente. A segunda vira conflito; o rascunho local é preservado e exige comparação/decisão. |
| Criança conclui missão offline e o responsável a arquiva antes da sincronização | Preservar o evento da criança e encaminhá-lo para decisão do responsável. Não descartar silenciosamente e não conceder estrelas automaticamente. Timestamp do aparelho não prova anterioridade. |
| Mesmo pedido chega duas vezes | Mesmo `operation_id` retorna o mesmo resultado, sem novo pedido ou débito. |
| Aprovação ou rejeição repetida/concorrente | Transição condicional a partir de `pending`; uma decisão vence, as demais recebem o estado final. Qualquer efeito financeiro exigido pela transição canônica é registrado uma única vez com sua própria `business_effect_key`. |
| Mimo solicitado com saldo alterado em outro aparelho | Servidor serializa a decisão por criança e usa o saldo confirmado. Se insuficiente, rejeita com motivo explícito, como `insufficient_balance`; o cliente reconcilia sem substituição silenciosa do saldo. |
| Dois aparelhos enviam ledger equivalente | `operation_id` deduplica retries; `business_effect_key` deduplica operações distintas para a mesma causa canônica. Somente um efeito financeiro equivalente é criado. |
| Aparelho retorna após longo período offline | Preserva a outbox não confirmada. Se o cursor/checkpoint de 30 dias não for mais válido, não continua o feed: obtém snapshot consistente, reconcilia operações locais e recebe novo cursor. |

Preferências de aparência por perfil + aparelho não participam dessa matriz porque não são compartilhadas e não geram conflito remoto.

## 9. Segurança e RLS

### 9.1 Responsável

As políticas existentes baseadas em `family_members` são uma base reaproveitável. O servidor deve sempre verificar associação à família e papel necessário. Operações críticas devem usar atualização condicional ou RPC transacional, não apenas permissões amplas de tabela.

### 9.2 Criança

O aparelho infantil só pode:

- visualizar suas missões;
- visualizar mimos disponíveis para ela;
- concluir/enviar missão;
- cancelar envio quando a regra permitir;
- pedir mimo;
- visualizar seu saldo, histórico pertinente e decisões recebidas.

Não pode:

- criar ou editar família;
- criar ou editar crianças;
- administrar missões ou mimos;
- aprovar ou rejeitar solicitações;
- inserir ledger arbitrário;
- alterar segurança;
- acessar dados de outras crianças.

Um gateway/RPC de escopo estrito deve resolver `family_id` e `child_id` a partir do vínculo autenticado, nunca do payload enviado pelo cliente. O backend valida relações, estados, repetição, custo, saldo, autorização e idempotência independentemente da UI.

### 9.3 Credenciais e revogação

- segredos em armazenamento seguro;
- tokens curtos com renovação ligada à chave do aparelho;
- revogação e rotação por vínculo;
- rate limiting no pareamento e nos endpoints sensíveis;
- auditoria sem segredos ou dados pessoais desnecessários;
- nenhuma credencial permanente fraca;
- nenhuma sessão de responsável no aparelho infantil.

Na arquitetura final, remover `UPDATE` comum do ledger e restringir sua criação a transações de domínio.

## 10. Offline e reconexão

Depois da configuração inicial online, dados já disponíveis e ações permitidas continuam funcionando localmente. Falta de internet, Supabase indisponível ou expiração de sessão não apagam conteúdo local.

No aparelho do responsável:

- leitura e uso local continuam;
- operações remotas ficam pendentes;
- renovação de token é tentada na reconexão;
- se a sessão não puder ser renovada, upload e pull administrativos aguardam reautenticação.

No aparelho infantil:

- a validade offline inicial do vínculo é de 48 horas contadas desde a última validação bem-sucedida com o backend;
- durante essas 48 horas, o aparelho pode usar os dados locais, concluir missões e criar pedidos de mimo;
- durante esse período, ações que dependem da nuvem são persistidas na outbox e enviadas depois;
- após 48 horas sem revalidar, o app ainda pode abrir e exibir os dados já armazenados, mas não pode criar novas ações sincronizáveis;
- para voltar à operação normal após esse limite, o aparelho deve recuperar a conexão e revalidar o vínculo;
- a revogação passa a valer no aparelho ao reconectar ou ao vencer essa validade offline.

As 48 horas são o valor inicial de produto. A arquitetura deve permitir que esse prazo seja configurado futuramente pelo backend, como política recebida e armazenada com a validação do vínculo, em vez de espalhar ou fixar a regra em diferentes pontos da aplicação.

O cache local deve estar vinculado à identidade da família correta. Autenticar outra conta não autoriza enviar dados da família anterior para a nova. Sem correspondência inequívoca, o sync é bloqueado e o usuário recebe recuperação orientada.

## 11. Restore

As duas restaurações existentes permanecem conceitualmente separadas.

### 11.1 Bootstrap de aparelho novo

Restaura somente em base local segura:

- família;
- crianças;
- missões;
- mimos.

Não restaura nessa fase:

- saldo;
- histórico;
- pedidos;
- conclusões;
- streak.

Em aparelho infantil, o bootstrap é limitado ao `child_id` do vínculo e não entrega snapshot administrativo da família.

### 11.2 Restauração histórica e saldo

- restaura logs, pedidos e ledger;
- recompõe `balanceAfter` e `ChildProfile.starBalance` pelo ledger;
- usa `child_star_balances` somente como conferência;
- não restaura streak;
- não faz merge implícito;
- não aplica parcialmente quando uma validação falha.

No sync V2, o restore fornece também o cursor correspondente ao mesmo snapshot. A aplicação só termina com snapshot e cursor gravados juntos. Se houver operações locais ainda não confirmadas, o sistema deve preservá-las e reconciliá-las antes de substituir estado relacionado, ou bloquear o restore. Um snapshot nunca apaga silenciosamente a outbox pendente.

Preferências locais de aparência, PIN, biometria e sessão não vêm do restore. Um novo aparelho começa com defaults do Zeni para cada perfil local.

## 12. Transição do sistema atual

O Zeni ainda não foi lançado publicamente com a arquitetura anterior. Portanto, esta fase não deve projetar uma migração genérica e complexa para famílias locais legadas.

Regras da transição:

- nunca associar silenciosamente `local-family` à primeira conta autenticada;
- iniciar o novo fluxo multi-dispositivo somente com identidade canônica criada ou autorizada;
- tratar dados de desenvolvimento e beta de forma controlada, com procedimentos compatíveis com o ambiente e sem convertê-los em regra geral do produto;
- se surgir no futuro uma necessidade real de incorporar uma família local, realizar isso por um fluxo explícito e separado, com confirmação de identidade e destino, nunca automaticamente.

A evolução técnica continua incremental:

1. formalizar contratos, estados e invariantes;
2. introduzir identidade canônica de família, criança e aparelhos;
3. adotar persistência local transacional para estado sincronizável, outbox e cursor;
4. migrar catálogos para revisões e tombstones;
5. migrar logs, pedidos e ledger para comandos/transições atômicos e idempotentes;
6. adicionar pareamento e autorização infantil somente após a fundação de segurança;
7. integrar restore com snapshot/cursor;
8. habilitar colaboração gradualmente por domínio, com métricas e possibilidade de rollback.

Novas operações devem possuir identificadores estáveis desde a criação local. Qualquer tratamento necessário para `local_id` ou `idempotency_key` de bases de desenvolvimento/beta deve ser deliberado, limitado e validado, sem pressupor uma migração pública legada.

Preferências de aparência por perfil + aparelho permanecem fora dessa transição remota. Se o armazenamento local precisar evoluir para suportar múltiplos perfis no mesmo aparelho, a migração será exclusivamente local e manterá defaults seguros quando não houver valor específico.

## 13. Riscos

- divergência entre saldo provisório local e saldo confirmado em outros aparelhos;
- perda de eventos se snapshots forem aplicados sobre outbox pendente;
- crédito ou débito duplicado por ausência ou validação insuficiente de `business_effect_key`;
- revogação que não alcança imediatamente um aparelho offline;
- persistência local atual sem transação entre estado e outbox;
- associação incorreta de IDs ou de uma `local-family` durante tratamentos controlados;
- vazamento entre famílias após troca de conta;
- permissões remotas amplas para atualização de status ou ledger;
- relógios dos aparelhos usados incorretamente para resolver conflitos;
- tombstones removidos antes de aparelhos muito antigos voltarem;
- experiência confusa para valores provisórios de estrelas e pedidos.

## 14. Perguntas abertas

Não restam perguntas arquiteturais abertas para o escopo aprovado da Sprint 1. Detalhes físicos de implementação e parâmetros operacionais futuros permanecem deliberadamente fora deste documento e devem respeitar os contratos e valores iniciais aqui definidos.

## 15. Próximas sprints recomendadas

### Sprint 2 — Contratos e identidade

- detalhar os contratos a partir das decisões consolidadas;
- especificar família, membros, aparelhos, vínculos e a transição controlada de dados de desenvolvimento/beta;
- definir estados e invariantes de autorização;
- preparar testes de ameaça e contratos, ainda sem colaboração ampla.

### Sprint 3 — Fundação do sync

- persistência local transacional;
- outbox durável;
- protocolo idempotente;
- ACK, cursor e retry;
- observabilidade e diagnóstico.

### Sprint 4 — Catálogos e conflitos

- revisões de família, crianças, missões e mimos;
- tombstones;
- conflito de edição concorrente;
- rollout gradual por domínio.

### Sprint 5 — Eventos e saldo

- transições protegidas de logs e pedidos;
- ledger estritamente append-only;
- serialização de efeitos de saldo;
- UX e reconciliação de estado provisório.

### Sprint 6 — Pareamento infantil

- identidade do aparelho infantil;
- código e QR;
- gateway de menor privilégio;
- vínculo, renovação e revogação.

### Sprint 7 — Restore e QA multi-dispositivo

- integração de snapshot e cursor;
- migração de dados reais;
- testes de corrida, duplicidade e offline prolongado;
- teste de aparelho perdido, revogação e recuperação;
- validação end-to-end entre parent device e child device.
