

---

<!-- 00_INDEX.md -->

# Zeni V2 — Base de Conhecimento

**Data de consolidação:** 2026-09-06  
**Objetivo:** registrar decisões de produto, UX, arquitetura visual, benchmark, IA, monetização e roadmap para orientar futuras implementações com ChatGPT/Codex/Cursor.

## Estado do projeto

O Zeni está em **pré-beta interno maduro**, com base offline-first forte, auth opcional, sync progressivo, ledger, restauração, RLS, testes e QA já estruturados.

A nova frente não é reconstruir o core técnico. É criar uma **Zeni V2 de experiência**, principalmente no modo criança, preservando as regras arquiteturais já validadas.

## Princípios não negociáveis

- O app funciona sem login, sem internet e sem Supabase.
- Login é opcional.
- Estado operacional principal permanece local.
- `ChildProfile.starBalance` local continua sendo a fonte operacional da UX.
- Supabase continua sendo camada progressiva.
- `child_star_balances` não vira fonte operacional.
- Não implementar merge automático agora.
- Não implementar realtime agora.
- Não restaurar streak.
- Não usar `SnackBar` ou `ScaffoldMessenger`.
- Logout não apaga dados locais.
- Wipe local não apaga nuvem.
- IA não pode se tornar requisito para o core funcionar.
- IA nunca altera saldo, ledger, aprovação ou missões sem ação explícita do responsável.

## Documentos desta base

1. `01_PRODUCT_VISION.md` — visão da Zeni V2 e proposta central.
2. `02_DESIGN_UX_V2.md` — Design System, criança, responsável, mascote, motion e offline.
3. `03_BENCHMARK_MARKET.md` — aprendizados de Joon, Greenlight e S’moresUp.
4. `04_AI_ARCHITECTURE_COSTS.md` — Zeni Ajuda, sugestões de missões, segurança, arquitetura e custos.
5. `05_MONETIZATION.md` — plano Free/Premium, preço e cenários econômicos.
6. `06_ROADMAP_SCOPE.md` — fases de implementação e escopo.
7. `07_DECISION_LOG.md` — decisões consolidadas e status.
8. `08_CODEX_CONTEXT.md` — contexto compacto para novas conversas/execuções.

## Regra de uso

Antes de qualquer grande alteração de UX, sync, ledger, restauração, IA ou monetização, consultar esta base e registrar a nova decisão em `07_DECISION_LOG.md`.



---

<!-- 01_PRODUCT_VISION.md -->

# Zeni V2 — Visão de Produto

## Problema que estamos resolvendo

O core funcional do Zeni está maduro, mas a interface atual não traduz a qualidade da arquitetura. O modo criança é percebido como pouco atraente, pouco intuitivo e excessivamente próximo de uma interface administrativa.

A Zeni V2 deve transformar o core existente em uma experiência:

- intuitiva;
- infantil sem ser "bebê";
- visualmente própria;
- motivadora;
- simples;
- acessível;
- expressiva;
- confiável;
- offline-first.

## Proposta central

**Missões viram pequenas conquistas.**

Fluxo principal:

`missão → ação da criança → feedback → aprovação quando necessária → estrelas → progresso → mimo`

O produto não deve ser percebido apenas como "gerenciador de tarefas".

A experiência deve comunicar:

- autonomia;
- responsabilidade;
- reconhecimento;
- progresso;
- participação da criança na rotina familiar.

## Papéis

### Criança

Precisa entender rapidamente:

1. O que tenho para fazer?
2. Quantas estrelas tenho?
3. Do que estou perto de conseguir?

A criança não deve ver complexidade administrativa.

### Responsável

Precisa entender rapidamente:

1. O que precisa da minha ação?
2. Como estão as crianças?
3. O que está pendente?
4. Como criar/editar missões e mimos rapidamente?

## Regra de produto compartilhado

Aprendizado absorvido de experiências de atuação compartilhada:

`usuário A realiza ação → ação tem autoria e estado → sincroniza → usuário B reage → resultado volta ao usuário A`

Aplicações no Zeni:

### Missão com aprovação

`criança conclui → pendingApproval → responsável aprova → ledger → saldo → celebração`

### Pedido de mimo

`criança pede → pending → responsável aprova/rejeita → criança recebe resultado`

## Missões normais e Missões Extras

### Missões normais

- atribuídas a uma criança;
- fazem parte da rotina principal.

### Missões extras

- voluntárias;
- dão oportunidade de ganhar estrelas adicionais;
- devem aparecer separadas das missões normais;
- linguagem sugerida: **"Quer ganhar mais estrelas?"**

A implementação precisa considerar concorrência/offline com cuidado. Não introduzir merge/realtime complexo apenas por causa desse recurso.

## Ideia futura: sugerir missão

A criança pode futuramente sugerir uma missão ao responsável.

Fluxo:

`criança sugere → responsável revisa/edita → define estrelas → aprova`

Nada é criado automaticamente.



---

<!-- 02_DESIGN_UX_V2.md -->

# Zeni V2 — Design, UX e DLS

## Fundação

A base técnica recomendada é:

`Flutter → Material 3 → Zeni Core Design System → Zeni Kids / Zeni Parent`

Material 3 é fundação técnica, não aparência final.

## Direção visual

Identidade preservada:

- verde Zeni `#22C55E`;
- amarelo estrela `#FACC15`;
- verde escuro `#16A34A`;
- texto `#1F2937`;
- cards claros;
- grandes raios;
- formas amigáveis;
- legibilidade alta;
- ícones simples;
- motion suave;
- mascote Zeni.

## Linguagem por papel

### Zeni Kids

**clareza + emoção + movimento**

- menos informação;
- uma ação dominante por estado;
- mascote;
- progresso visual;
- recompensas;
- glow/confete/zoom;
- feedback imediato.

### Zeni Parent

**clareza + eficiência**

- mais sóbrio;
- menos decoração;
- maior densidade de informação;
- foco em pendências, gestão e aprovação.

## Home da criança

Deve tender a:

- saudação;
- saldo de estrelas visível;
- mascote;
- progresso do dia;
- próxima missão em destaque;
- próximas missões;
- seção de missões extras;
- entrada discreta para ajuda/IA;
- navegação simples.

Evitar dashboard cheio de números.

## Regra de uma ação dominante

Exemplo de card infantil:

**Arrumar a cama**  
`+5 ⭐`  
`CONCLUIR`

Não mostrar no mesmo card infantil:

- editar;
- recorrência;
- histórico;
- calendário;
- configurações;
- opções administrativas.

## Home do responsável

Prioridade:

### Precisa de você

Consolidar:

- missões aguardando aprovação;
- pedidos de mimo;
- demais ações que exigem decisão.

Evitar espalhar pendências por várias áreas.

## Criar missão

Fluxo básico deve levar poucos segundos:

1. Nome.
2. Estrelas.
3. Criança.
4. Salvar.

Recorrência, aprovação, horário e demais opções entram em **Mais opções**.

## Mascote

Decisão atual: **estático + motion nativo Flutter**, sem Rive na V2 inicial.

Conjunto previsto de estados:

- `idle`
- `encourage`
- `waitingApproval`
- `celebrating`
- `sleeping`
- `thinking`
- `rewardClose`
- `achievement`

Criar um único componente:

`ZeniMascot(state: ...)`

A tela não deve conhecer diretamente o arquivo PNG.

## Motion

Usar Flutter para:

- `AnimatedScale`;
- `AnimatedOpacity`;
- `AnimatedSlide`;
- `AnimatedSwitcher`;
- `TweenAnimationBuilder`;
- `AnimationController`;
- partículas/confete;
- glow;
- estrela voando até o saldo;
- bounce;
- contagem animada do saldo.

### Missão concluída

Sequência sugerida:

1. card reduz levemente;
2. volta com spring;
3. check aparece;
4. estrelas surgem;
5. estrela voa ao saldo;
6. saldo conta para cima;
7. glow;
8. mascote troca para celebração;
9. `scale 0.88 → 1.06 → 1.0`;
10. confete curto.

## Offline / conectividade

Criar componente global:

`ZeniConnectivityPill`

Estados:

- `offline`
- `syncing`
- `synced`
- `syncError`

### Criança

Mensagem simples:

**Sem internet · Suas missões continuam funcionando**

Sem termos técnicos.

### Responsável

Pode explicar:

- dados continuam salvos;
- novidades serão atualizadas quando a internet voltar;
- alterações aguardando sync.

Estar offline não é erro no Zeni.

## Assets financeiros

Regra atual:

- estrela = moeda operacional;
- presente = mimo;
- dinheiro real somente se um módulo explícito de mesada for criado no futuro.

Não misturar notas de dinheiro com saldo de estrelas na UX principal.



---

<!-- 03_BENCHMARK_MARKET.md -->

# Zeni V2 — Benchmark de Mercado

## Objetivo

Não copiar identidade de concorrentes. Aproveitar padrões de interação, aprendizados de avaliações e mecanismos de aquisição/conversão.

## Joon

### O que funciona

- simplicidade para criança;
- missão como "quest";
- recompensa imediata;
- personagem/pet;
- progressão visual;
- leitura em voz alta;
- percepção dos pais de "menos cobrança";
- criança entende ação → recompensa.

### Riscos/aprendizados

- assinatura/trial pode gerar rejeição;
- responsável também pode enfrentar complexidade;
- dependência de internet gera frustração;
- gamificação pode perder novidade;
- não adotar posicionamento clínico/TDAH como identidade do Zeni;
- não depender exclusivamente de pet/gamificação.

### O que trazer

- clareza infantil;
- feedback imediato;
- personagem;
- uma ação principal por estado;
- TTS;
- pequena sensação de conquista.

## Greenlight

### O que funciona

- separação clara entre responsável e criança;
- saldo e objetivo;
- tarefas com aprovação;
- autonomia;
- tarefas "up for grabs";
- forte prova social;
- hierarquia de informação;
- confiança de marca.

### Ideias relevantes

- Missões Extras;
- criança sugerir uma missão;
- objetivo visual para mimo;
- clareza de quanto falta para atingir recompensa.

### O que não copiar agora

- dinheiro real;
- fintech;
- transferências;
- complexidade financeira.

## S’moresUp

### Principais críticas observadas

- interface confusa;
- muitas opções;
- criação de tarefas trabalhosa;
- sync percebido como lento;
- pontos/saldo gerando desconfiança;
- histórico insuficiente;
- pendências espalhadas;
- experiência ruim em tablet;
- assinatura/preço gerando frustração.

### O que isso ensina

1. Uma ação principal por tela da criança.
2. Criar missão básica em segundos.
3. Progressive disclosure.
4. Estado compartilhado sempre explícito.
5. Um hub "Precisa de você".
6. Saldo auditável via ledger.
7. Validar celular e tablet.
8. Motion deve confirmar ação, não esconder complexidade.

## Prova social

Não usar prova social inventada.

Métricas futuras possíveis:

- downloads reais de lojas;
- nota real;
- avaliações reais;
- número de famílias com definição clara;
- missões concluídas/sincronizadas.

Evitar claims vagos sem fonte.

## Aquisição / marketing

Aprendizados:

- anúncios falam com o responsável;
- dor é mais forte que lista de features;
- confiança precisa aparecer cedo;
- marketing pode usar criança real + UI do Zeni;
- o app pode ser ilustrado sem o marketing precisar ser 100% cartoon.

Possíveis mensagens:

- **Menos cobrança. Mais autonomia.**
- **Transforme responsabilidades em pequenas conquistas.**
- **Pequenas responsabilidades. Grandes conquistas.**



---

<!-- 04_AI_ARCHITECTURE_COSTS.md -->

# Zeni V2 — IA, Arquitetura, Segurança e Custos

## Princípio

Não criar "um ChatGPT dentro do Zeni".

IA deve ser uma capacidade contextual, controlada e opcional.

O core continua funcionando sem internet e sem IA.

## Produtos de IA

### 1. Zeni Ajuda — criança

Entradas estruturadas:

- **Dúvida da escola**
- **Quero entender alguma coisa**
- **Me ajuda nesta missão**
- **O que significa isso?**
- **Me faça uma pergunta**

Objetivo:

- explicar;
- dividir problema em passos;
- incentivar;
- ensinar sem entregar tudo imediatamente;
- respostas curtas;
- linguagem adequada à idade.

### 2. Zeni Copiloto — responsável

Exemplo:

> "Quero que meu filho de 9 anos organize melhor o material escolar."

Resposta estruturada pode sugerir:

- título da missão;
- descrição;
- estrelas;
- categoria;
- recomendação de aprovação.

Regra:

**IA sugere → responsável revisa → responsável aprova**

Nunca criar automaticamente.

## Coach da missão

Caso de alto valor:

A criança toca em **"Não sei como fazer"**.

A Zeni divide a missão em pequenos passos.

Isso conecta IA ao core do produto e diferencia mais do que um chat genérico.

## Arquitetura recomendada

`Flutter → Zeni AI Gateway → regras → model router → provider/modelo → validação → Flutter`

Implementação sugerida do Gateway:

- Supabase Edge Function ou backend equivalente;
- chave da API nunca no Flutter;
- rate limits;
- autenticação quando necessária;
- logs;
- quotas;
- moderação;
- validação de schema.

## Provider-neutral

Criar camada que permita trocar de fornecedor sem mexer no Flutter.

Inicialmente, usar **um provider com dois níveis de modelo** é mais simples do que manter vários fornecedores.

## Roteamento por custo

### Modelo econômico

Usar para:

- sugestão de missão;
- reescrita infantil;
- classificação;
- explicação simples;
- dividir missão em passos;
- perguntas escolares simples.

### Modelo intermediário

Usar somente quando:

- pergunta exige raciocínio maior;
- planejamento complexo;
- fallback de qualidade.

### Modelo topo de linha

Não usar por padrão na V1.

## Estratégia de custo

O melhor request é o que não acontece.

Fluxo:

`conteúdo local → resolve? → sim: custo zero / não: IA econômica → difícil? → modelo melhor`

Criar biblioteca local para perguntas e passos recorrentes.

## Limites

Beta deve começar com quotas.

Exemplos de planejamento:

- responsável: quantidade limitada de sugestões/mês;
- criança: sessões curtas/dia;
- número máximo de turnos;
- tamanho máximo de pergunta;
- respostas curtas;
- sem conversa infinita.

A quota final deve ser definida a partir de telemetria real.

## Segurança infantil

Regras fundamentais:

- nunca pedir segredo;
- nunca substituir o responsável;
- nunca pedir endereço, telefone, escola ou dados pessoais desnecessários;
- não navegar livremente na web no modo criança;
- não decidir punições;
- não alterar estrelas;
- não aprovar missões;
- não criar vínculo privado persistente com a criança;
- temas sensíveis devem acionar política específica;
- saúde não vira diagnóstico;
- assuntos delicados podem orientar a procurar um responsável confiável.

## Pipeline de segurança

`pergunta → regras locais → moderação/classificação → modelo → output estruturado → validação/moderação → criança`

## Dados mínimos

### Sugestão de missão

Enviar apenas algo como:

- faixa etária;
- objetivo;
- contexto;
- dificuldade;
- idioma.

### Escola

- ano/faixa escolar;
- pergunta;
- idioma.

Evitar PII.

## Telemetria de IA

Registrar:

- tipo de tarefa;
- modelo;
- tokens de entrada;
- tokens de saída;
- custo estimado;
- latência;
- bloqueado/sucesso;
- família anonimizada;
- versão do prompt/policy.

## Custos

Os valores de modelos mudam. Toda cifra abaixo deve ser tratada como **hipótese de planejamento datada**, não como contrato.

Premissa conceitual:

- sugestão de missão é barata;
- chat longo custa mais;
- roteamento e limites tornam IA economicamente previsível.

Antes da produção:

1. escolher provider;
2. coletar preço atualizado;
3. criar benchmark com ~100 prompts reais;
4. medir qualidade, custo e latência;
5. definir roteamento.



---

<!-- 05_MONETIZATION.md -->

# Zeni V2 — Monetização e Unit Economics

## Princípio comercial

Não adotar paywall agressivo no primeiro contato.

A família deve perceber valor antes de ser convidada ao Premium.

Não cobrar por criança. Cobrar por **família**.

## Estrutura proposta

### Zeni Free

Deve continuar entregando o coração do produto:

- missões;
- estrelas;
- mimos;
- modo criança;
- operação offline;
- experiência essencial.

Não colocar segurança básica ou histórico essencial atrás de paywall.

### Zeni Família

Hipótese inicial de preço:

- **R$ 19,90/mês**
- **R$ 149,90/ano**

Possível preço fundador:

- **R$ 14,90/mês**
- **R$ 109,90/ano**

Recursos Premium candidatos:

- compartilhamento entre responsáveis;
- sync/backup/restauração;
- experiência multiaparelho;
- sugestões inteligentes;
- Zeni Ajuda com limite justo;
- futuros recursos familiares.

## Observação

Premium/assinatura continua fora do core imediato até validação do produto e beta.

## Hipóteses de custos

Para planejamento foram considerados:

- taxa de loja;
- infraestrutura;
- RevenueCat quando aplicável;
- custo mensal de IA por família;
- suporte/reembolsos/impostos fora da margem de contribuição.

As cifras precisam ser atualizadas antes de decisão comercial real.

## Cenário de referência mensal

Hipótese simplificada usada na conversa:

- preço: R$ 19,90/mês;
- taxa loja: 15%;
- IA: reserva inicial de ~R$ 0,60/família/mês;
- infraestrutura fixa: ~R$ 200/mês;
- RevenueCat: considerar custo quando ultrapassar faixa gratuita.

### Resultado ilustrativo

| Famílias pagantes | Receita bruta/mês | Margem de contribuição aproximada | Aproximado por família |
|---:|---:|---:|---:|
| 100 | R$ 1.990 | ~R$ 1,43 mil | ~R$ 14,32 |
| 1.000 | R$ 19.900 | ~R$ 15,9 mil | ~R$ 15,92 |
| 10.000 | R$ 199.000 | ~R$ 160,9 mil | ~R$ 16,10 |

**Não confundir com lucro líquido contábil.**

Ainda faltam:

- impostos;
- CAC/marketing;
- suporte;
- reembolsos;
- despesas administrativas;
- eventuais custos extras de nuvem.

## Principal risco econômico

Provavelmente não será IA.

O maior risco tende a ser:

**CAC alto + churn alto**

Exemplo conceitual:

- família orgânica que permanece 12 meses = ótima economia;
- família adquirida por mídia paga cara que cancela em 1 mês = economia ruim.

## Métrica principal futura

Acompanhar por coorte:

- CAC;
- conversão Free → Premium;
- churn;
- LTV;
- custo médio de IA/família;
- custo de nuvem/família;
- margem de contribuição.



---

<!-- 06_ROADMAP_SCOPE.md -->

# Zeni V2 — Roadmap e Escopo

## Estratégia

Não redesenhar 30 telas antes de validar a nova linguagem.

Construir um **vertical slice** primeiro.

## Fase 1 — Experience Foundation

- congelar Zeni Kids DS;
- Material 3 como fundação;
- tokens;
- motion;
- `ZeniMascot`;
- `ZeniConnectivityPill`;
- Home criança V2;
- Home responsável V2;
- hub `Precisa de você`.

Sem alterar:
- ledger;
- regras de saldo;
- restore;
- auth;
- sync core.

## Fase 2 — Jornada criança

- Missões;
- detalhe/conclusão;
- aprovação;
- celebração;
- saldo;
- histórico visual simplificado;
- Mimos;
- progresso até mimo.

## Fase 3 — Missões Extras

- seção separada;
- disponibilidade;
- seleção voluntária;
- regras conservadoras para offline/concorrência;
- sem criar realtime complexo.

## Fase 4 — Shared Family

Aproveitar aprendizados de atuação compartilhada:

- estados explícitos;
- pendências centralizadas;
- feedback claro de sync;
- responsável A/responsável B;
- evitar merge automático.

## Fase 5 — Zeni AI Beta

Começar pelo maior valor/menor risco:

1. sugestão de missões para responsável;
2. coach de missão;
3. dúvidas simples;
4. tutor escolar mais amplo somente depois.

IA:
- online-only;
- limitada;
- monitorada;
- provider-neutral;
- sem acesso direto a saldo/ledger.

## Fase 6 — Monetização

Somente depois de:
- UX validada;
- beta real;
- telemetria;
- uso real de IA;
- clareza de custos;
- entendimento de conversão.

## O que não fazer agora

- Rive;
- merge automático;
- realtime amplo;
- multi-dispositivo colaborativo completo;
- saldo remoto operacional;
- redesign simultâneo de todas as telas;
- premium antes de validar valor;
- chat infantil aberto;
- IA tomando decisões;
- exclusão remota nova na UI;
- gamificação profunda tipo videogame.



---

<!-- 07_DECISION_LOG.md -->

# Zeni V2 — Decision Log

Legenda:

- **FECHADO** — orientação atual.
- **VALIDAR** — hipótese forte, mas precisa teste.
- **FUTURO** — boa ideia, fora da fase imediata.

## PDR-001 — Material 3 como fundação

**Status:** FECHADO

Material 3 será a infraestrutura técnica do DLS, sem aparência Material padrão.

## PDR-002 — Zeni Kids e Zeni Parent distintos

**Status:** FECHADO

- Kids: clareza + emoção + movimento.
- Parent: clareza + eficiência.

## PDR-003 — Mascote estático na V2 inicial

**Status:** FECHADO

Não usar Rive agora.

Usar PNGs consistentes + motion nativo Flutter.

## PDR-004 — Mascote oficial Zeni

**Status:** FECHADO

Personagem estrela alinhado à identidade da marca.

Evitar novas gerações que alterem drasticamente o modelo visual.

## PDR-005 — Motion Flutter

**Status:** FECHADO

Zoom, bounce, glow, confete, estrelas e contadores serão feitos nativamente.

## PDR-006 — Hub "Precisa de você"

**Status:** FECHADO

Responsável deve ter um único local para ações pendentes.

## PDR-007 — Progressive disclosure

**Status:** FECHADO

Criação de missão básica deve ser simples. Opções avançadas ficam em "Mais opções".

## PDR-008 — Missões Extras

**Status:** FECHADO PARA V2 / IMPLEMENTAÇÃO A VALIDAR

Entram como categoria separada e voluntária.

Concorrência/offline deve ser resolvida sem introducir merge/realtime amplo.

## PDR-009 — Indicador offline persistente

**Status:** FECHADO

Criar `ZeniConnectivityPill`.

Offline é estado normal, não erro.

## PDR-010 — IA não é chat aberto

**Status:** FECHADO

IA entra por ações estruturadas e contexto.

## PDR-011 — Zeni Ajuda

**Status:** VALIDAR EM BETA

Coach de missão + dúvidas simples + explicação infantil.

## PDR-012 — Zeni Copiloto

**Status:** VALIDAR EM BETA

Sugere missões ao responsável.

IA nunca cria/edita automaticamente sem revisão.

## PDR-013 — Arquitetura de IA

**Status:** FECHADO

Flutter não contém chave.

Usar AI Gateway backend + roteamento + moderação + quotas.

## PDR-014 — IA provider-neutral

**Status:** FECHADO

Flutter não deve depender de um provider específico.

## PDR-015 — Free + um plano família

**Status:** HIPÓTESE COMERCIAL

Evitar múltiplos tiers inicialmente.

## PDR-016 — Preço de referência

**Status:** VALIDAR

- R$ 19,90/mês.
- R$ 149,90/ano.
- preço fundador possível.

Reavaliar antes de lançamento Premium.

## PDR-017 — Prova social

**Status:** FECHADO

Nunca inventar números/depoimentos.

Usar métricas reais e definidas.

## PDR-018 — Benchmark

**Status:** FECHADO

- Joon: clareza/motivação infantil.
- Greenlight: autonomia, recompensa, confiança.
- S’moresUp: principalmente aprendizados do que evitar.
- identidade final: Zeni própria.



---

<!-- 08_CODEX_CONTEXT.md -->

# Contexto compacto — Zeni V2

Estou trabalhando no Zeni, app Flutter familiar de missões, mimos, estrelas e atuação entre criança/responsável.

## Arquitetura obrigatória

- offline-first;
- login opcional;
- estado operacional local;
- `ChildProfile.starBalance` local é fonte da UX;
- Supabase é camada progressiva;
- não usar saldo remoto como fonte operacional;
- não implementar merge automático;
- não implementar realtime amplo agora;
- não restaurar streak;
- não usar SnackBar/ScaffoldMessenger;
- logout preserva local;
- wipe local não apaga nuvem.

## Nova direção Zeni V2

O problema principal atual é visual/UX, especialmente no modo criança.

Fundação:

`Flutter → Material 3 → Zeni Core DS → Zeni Kids / Zeni Parent`

### Kids

- interface radicalmente simples;
- mascote Zeni;
- saldo;
- progresso;
- próxima missão;
- missões extras;
- mimos;
- motion Flutter.

Mascote será estático em PNG + AnimatedScale/AnimatedSwitcher/glow/confete/bounce. Não usar Rive agora.

### Parent

- sóbrio e eficiente;
- Home começa por `Precisa de você`;
- pendências centralizadas;
- criação básica de missão em poucos passos;
- opções avançadas em `Mais opções`.

## Missões Extras

Entram na V2 como fluxo separado e voluntário.

Evitar que isso force merge/realtime complexo.

## Offline

Criar `ZeniConnectivityPill` global:

- offline;
- syncing;
- synced;
- syncError.

Criança: linguagem simples.  
Responsável: pode ver mais detalhes.

## Benchmark

- Joon: referência de simplicidade e motivação infantil.
- Greenlight: referência de autonomia, saldo, metas, confiança.
- S’moresUp: alertas de complexidade, sync, saldo e UX.
- Não clonar identidade; adaptar padrões.

## IA

Não criar chat aberto.

Criar:

1. `Zeni Ajuda` para criança:
   - dúvida da escola;
   - explicar conceito;
   - coach da missão;
   - dividir em passos.

2. `Zeni Copiloto` para responsável:
   - sugerir missão;
   - sugerir descrição/estrelas/categoria.

Arquitetura:

`Flutter → AI Gateway backend → regras → model router → modelo → validação`

- chave nunca no app;
- provider-neutral;
- modelo barato por padrão;
- modelo melhor só quando necessário;
- quotas;
- moderação;
- respostas estruturadas;
- IA nunca altera saldo, ledger ou aprovação.

## Monetização

Hipótese futura:

- Free funcional.
- Um plano Zeni Família.
- referência: R$ 19,90/mês ou R$ 149,90/ano.
- não implementar Premium antes de validar beta e custos reais.

## Próximo passo

Não redesenhar o app inteiro.

Construir primeiro:

1. foundation/DLS;
2. Home criança V2;
3. jornada missão → conclusão → aprovação → estrelas;
4. mimos;
5. Home responsável / Precisa de você;
6. missões extras;
7. só depois IA beta.



---

# Atualização — 2026-09-06 — Modelo Inteligente e Idiomas

## Decisão de idiomas

Idiomas planejados para lançamento:

- Português do Brasil (`pt-BR`) — principal.
- Inglês (`en`) — lançamento global.
- Espanhol (`es`) — lançamento, usando linguagem internacional/neutra.
- Francês (`fr`) — idioma estratégico adicional.

Alemão permanece candidato para uma segunda onda.

## Decisão: duas camadas de inteligência

O Zeni não dependerá de IA para toda ajuda.

### 1. Conteúdo inteligente local

- JSON/local asset.
- Funciona offline.
- Custo zero.
- Respostas previsíveis.
- Missões sugeridas, passos, incentivo e mensagens de conclusão.
- Mesmo ID em todos os idiomas.

### 2. IA online

- Somente fallback ou personalização.
- Usada para perguntas livres e casos não cobertos.
- Precisa de internet.
- Usa backend/API, nunca chave dentro do Flutter.
- Não altera saldo, ledger, missões ou aprovações autonomamente.

## Regra operacional

`local first → AI only when needed`

Essa abordagem protege:

- offline-first;
- custo;
- privacidade;
- previsibilidade infantil;
- sustentabilidade financeira.

## Implementação inicial

Foi criada a especificação **Zeni Smart Content v0.1**, com:

- 12 missões comuns;
- 4 idiomas;
- faixas etárias;
- estrelas sugeridas;
- elegibilidade como missão extra;
- passos de ajuda;
- frases de incentivo;
- mensagens de conclusão;
- regras de seleção;
- regras de handoff futuro para IA.



---

# Atualização — 2026-09-06 — Smart Content Master v1.0

## Conteúdo aprovado

Foi congelada a primeira versão oficial da biblioteca inteligente local do Zeni:

- 94 missões aprovadas;
- 26 rotinas aprovadas;
  - 20 principais;
  - 6 contextuais;
- 8 domínios;
- 6 idiomas:
  - pt-BR;
  - en;
  - es;
  - fr;
  - de;
  - ja.

## Decisão estrutural

A biblioteca passa a usar:

`global metadata + localized text`

Os metadados operacionais são globais e os textos apresentados à família ficam separados por locale.

Os IDs desta v1.0 devem ser tratados como estáveis.

## Internacionalização

A base é global e não cria um catálogo independente por país.

- idioma/localização adapta texto e tom;
- relevância cultural pode ser global ou contextual;
- preferências e escolhas reais da família têm prioridade sobre suposições por nacionalidade;
- revisão por falante nativo é recomendada antes de campanhas comerciais grandes, sem alterar a estrutura/IDs.

## Autonomia e neurodiversidade

Não existe “modo TDAH” ou “modo autismo”.

Apoios são configuráveis por necessidade:

- uma etapa por vez;
- apoio visual;
- TTS;
- timer opcional;
- aviso de transição;
- repetição;
- ordem fixa/flexível;
- intensidade de celebração;
- redução gradual de apoio.

Caminho de autonomia:

`com apoio → lembrete → independente`

## Motor local

O Smart Content deve funcionar offline.

Fluxo:

`idade + contexto + configuração da família → filtros → ranking → até 5 sugestões → responsável revisa/edita → salva`

IA continua sendo uma camada futura de fallback/personalização online.

Ela não é necessária para a primeira implementação de “Sugerir missões”.

## Próximo passo técnico

Integrar `zeni_smart_content_master_v1_0` no projeto Flutter atual por meio de:

- `SmartContentRepository`;
- `SmartContentService`;
- modelos de `MissionSuggestion`;
- modelos de `RoutineTemplate`.

Não alterar saldo, ledger, sync, restore, auth ou demais regras offline-first durante essa integração.
