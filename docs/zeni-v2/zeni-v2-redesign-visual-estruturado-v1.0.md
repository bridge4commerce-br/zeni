# Zeni V2 — plano de redesign visual estruturado

**Versão:** 1.0
**Data da auditoria:** 9 de setembro de 2026
**Branch auditada:** `feature/zeni-v2-visual`
**Estado analisado:** worktree atual, incluindo alterações locais já existentes
**Natureza:** diagnóstico e direção visual; nenhuma implementação faz parte deste documento

## Resumo executivo

O Zeni já possui uma fundação técnica visual válida: Material 3, Fredoka, opção OpenDyslexic, tema claro/escuro, escala de espaçamento, raios, componentes-base, quatro breakpoints únicos e helpers responsivos. O redesign não precisa substituir essa base, mas transformá-la em um design system semântico, adotado de ponta a ponta.

Hoje a interface é coerente no nível de marca — verde, estrelas, emojis, formas arredondadas — porém inconsistente no nível de sistema. A mesma importância visual é dada a muitos blocos; listas são frequentemente compostas por uma sequência de cards; tamanhos e pesos aparecem definidos localmente; telas centrais não usam a fundação responsiva; e a adaptação para tablet alterna entre reorganizar conteúdo e apenas ampliar medidas.

A direção proposta é um único **Core DS V2**, com duas expressões:

- **Zeni Kids:** expressivo, visual, acolhedor, com mascote funcional, mais respiro, leitura imediata e uma ação dominante por contexto.
- **Zeni Parent:** sóbrio, eficiente, orientado a listas e decisões, com maior densidade útil e menos decoração, sem perder a identidade Zeni.

O piloto Kids deve ser **Child Home**. O piloto Parent deve ser **Parent Missions**. Eles devem validar os tokens, as superfícies, a tipografia, a responsividade, a navegação e os padrões de estado antes do rollout.

## 1. Diagnóstico visual atual

### 1.1 Fundações existentes

| Área | Estado atual | Avaliação |
|---|---|---|
| Tema | `ZeniTheme.light` e `dark`, baseados em Material 3 | Boa base, mas ainda pouco semântica |
| Tipografia | `TextTheme` global com Fredoka | Coerente com a marca, porém incompleto e excessivamente pesado |
| Fredoka | Pesos 300–700 registrados | Adequado; w800/w900 usados no código não existem nos assets |
| OpenDyslexic | Override global opcional, pesos 400 e 700 | Boa capacidade, mas falta uma escala própria para evitar pesos sintetizados e alturas inadequadas |
| Cores | Marca, acento, apoio, estados, claro e escuro | Paleta compacta, mas mistura papel semântico e cor nominal |
| Espaçamento | 4, 8, 12, 16, 24, 32 e 48 | Escala boa; medidas locais 2, 5, 18, 20, 40, 44, 52, 56, 68, 92, 96 etc. escapam do sistema |
| Raios | 8, 12, 20, 28, 36 e pill | Boa base; há valores locais como 16 e 18 |
| Sombras | `card`, `soft`, `button` | Consistentes no claro, sem papel explícito por modo ou superfície |
| Botões | Primary, Secondary, Text, FAB e icon action | Cobertura inicial boa; faltam tamanhos/densidades Kids e Parent, hierarquia de perigo e estados comuns |
| Cards | `ZeniCard` único | Muito genérico; toda superfície recebe borda e sombra semelhantes |
| Chips | `ChoiceChip` direto em features | Sem token de altura, tipografia, estado ou expressão por modo |
| Navegação | `ZeniBottomNavBar` para Kids e Parent em todas as larguras | Funcional e estável; Parent desperdiça espaço em telas largas |
| Modal | sheet global e helper adaptativo | A estratégia adaptativa existe, mas sua adoção é parcial |
| Responsividade | breakpoints corretos e três larguras de página | Fundação sólida; adoção desigual entre telas |
| Touch targets | tokens de 48 e 56 | Intenção correta; `ZeniIconActionButton` usa 44 por padrão e os tokens não são aplicados sistematicamente |

### 1.2 Evidências de fragmentação

Varredura estática do estado auditado:

- 58 usos de `ZeniCard` nas features;
- 28 chamadas a `showModalBottomSheet`, mas apenas 4 decisões explícitas por `ZeniAdaptiveModal.usesDialog`;
- 10 usos de `ZeniPageFrame` entre 130 arquivos Dart de feature;
- 55 construções diretas de `TextStyle`;
- 43 usos diretos de `BorderRadius.circular`;
- 77 expressões diretas de `EdgeInsets`;
- 6 usos explícitos de w700, 14 de w800 e 15 de w900.

Os números não são erros isoladamente; mostram que as primitivas não estão absorvendo decisões visuais recorrentes.

### 1.3 Tipografia atual

A escala atual cobre `displayLarge`, headlines, titles, bodies e `labelLarge`, mas não nomeia o papel do texto no produto. Como consequência, `titleLarge` representa tanto seção quanto conteúdo de card, e estilos locais corrigem o resultado caso a caso.

Problemas principais:

- w800 e w900 são solicitados, mas a Fredoka embarcada só possui até w700; o resultado depende de peso sintético e perde consistência entre plataformas;
- o override OpenDyslexic troca a família, mas preserva pesos 500, 600, 800 e 900 que não existem na família cadastrada;
- `ParentMissionTypography` aumenta estilos em 12% em expanded/large, o que é uma correção local e escala o texto em vez de resolver layout e largura de linha;
- emojis têm tamanhos locais recorrentes entre 18 e 42, sem escala semântica;
- a hierarquia depende demais de bold: título, valor, custo, badge, botão e item selecionado competem pelo mesmo sinal.

### 1.4 Cor e contraste

Contrastes calculados sobre branco no estado atual:

- `primary` `#22C55E`: 2,28:1;
- `primaryDark` `#16A34A`: 3,30:1;
- `mutedText` `#6B7280`: 4,83:1;
- `text` `#1F2937`: 14,68:1.

No tema escuro, `mutedText` sobre `darkSurface` chega a aproximadamente 2,83:1. Portanto:

- verde atual funciona como preenchimento, ilustração e realce, mas não como texto normal sobre branco;
- branco sobre o verde primário atual não deve ser assumido como combinação acessível para labels de botão;
- `mutedText` está no limite aceitável no claro e inadequado quando aplicado estaticamente no escuro;
- cores de texto precisam vir de papéis semânticos do `ColorScheme`, não de constantes claras compartilhadas entre temas.

### 1.5 Responsividade atual

Os breakpoints existentes estão corretos e devem ser preservados:

- compact: `<600`;
- medium: `600–839`;
- expanded: `840–1199`;
- large: `>=1200`.

Também já existem `focus`, `main` e `dashboard`, `ZeniAdaptiveGrid` e `ZeniAdaptiveModal`. O problema é de aplicação:

- Child Home usa `ZeniPageFrame` e uma matriz própria de métricas; é o caso mais maduro, mas amplia muitos elementos no tablet;
- Parent Home usa frame e reorganização em grid;
- Child Missions, Rewards e Balance aplicam padding direto e ficam fluidos demais no tablet;
- Parent Missions, Rewards, Family e Settings aplicam padding direto, sem limite de largura consistente;
- a navegação inferior permanece de ponta a ponta mesmo com cinco destinos no Parent;
- a maioria dos modais continua bottom sheet em tablet.

### 1.6 Uso excessivo de containers e cards

O `ZeniCard` aplica sempre superfície, borda e sombra. Como ele representa destaque, lista, vazio, resumo, progresso, formulário e bloco dentro de modal, muitas telas viram uma pilha de caixas de peso semelhante.

Casos que devem ser reduzidos:

- cada missão ativa do Parent como card independente;
- cada item aguardando aprovação como card sem diferenciação estrutural;
- card dentro de modal já apresentado sobre uma superfície elevada;
- empty states com a mesma moldura de conteúdo acionável;
- cards usados apenas para criar padding;
- banner de sugestões competindo com a tarefa principal da tela;
- cards aninhados em detalhes de criança, aprovação e recompensa.

## 2. Problemas sistêmicos

1. **Tokens primitivos sem tokens semânticos.** Há verde, raio e espaçamento, mas não há `textPrimary`, `surfaceInteractive`, `spaceSection`, `radiusParentCard` ou `actionPrimaryChild`.
2. **Um componente para muitos papéis.** `ZeniCard` não distingue destaque, agrupamento, item de lista e estado vazio.
3. **Hierarquia por peso, não por composição.** Bold e caixas substituem contraste de escala, espaço, alinhamento e agrupamento.
4. **Responsividade local.** Algumas telas conhecem os breakpoints, outras só ganham mais espaço em volta.
5. **Tablet tratado parcialmente como celular ampliado.** A matriz de Child Home aumenta mascote, padding, emoji e gaps; Parent Missions aumenta tipografia 12% sem alterar a estrutura.
6. **Modalidade inconsistente.** Operações equivalentes aparecem como sheet ou dialog dependendo do arquivo, não do viewport e do tipo de tarefa.
7. **Claro e escuro compartilham constantes inadequadas.** `mutedText` e verdes de texto não mudam de papel por tema.
8. **Kids e Parent diferem por conteúdo, não por expressão sistematizada.** Falta uma camada de densidade, decoração e prioridade adequada a cada audiência.
9. **Acessibilidade declarada, mas não integral.** Há escala de texto, TTS, semântica e OpenDyslexic, porém pesos, contraste, largura de linha e touch targets ainda não são governados em conjunto.

## 3. Proposta de Core DS V2

### 3.1 Arquitetura visual

O Core DS deve ter quatro camadas:

1. **Primitivos:** paleta, escala tipográfica, espaçamento, raio, elevação, ícones, movimento e touch targets.
2. **Papéis semânticos:** texto, superfície, borda, ação, feedback, seleção e foco.
3. **Componentes:** botão, item de lista, chip, card de destaque, empty state, header, navigation e modal.
4. **Expressão:** `kids` e `parent`, alterando densidade, raio, decoração e prioridade sem duplicar componentes nem regras funcionais.

### 3.2 Cor semântica proposta

Manter o verde como marca, mas separar marca de acessibilidade:

| Papel | Claro proposto | Uso |
|---|---:|---|
| `brand` | `#22C55E` | mascote, progresso, ilustração, seleção decorativa |
| `actionPrimary` | `#15803D` | fundo de botão e controles; contraste com branco ≈ 5,02:1 |
| `actionPrimaryPressed` | `#166534` | estado pressionado |
| `textPrimary` | `#17211B` | títulos e corpo principal |
| `textSecondary` | `#526057` | metadados e apoio |
| `canvas` | `#F8FAF7` | fundo de página |
| `surface` | `#FFFFFF` | controles e superfícies elevadas |
| `surfaceSubtle` | `#F0FDF4` | agrupamento leve e estado selecionado |
| `borderSubtle` | `#DDE5DF` | separadores e contornos essenciais |
| `accentStar` | `#FFD166` | estrela/ilustração, nunca texto |
| `focus` | `#1D4ED8` | foco de teclado e acessibilidade |

No escuro, criar equivalentes sem reutilizar `mutedText`: canvas profundo, superfície um passo acima, `textPrimary` claro e `textSecondary` com contraste mínimo de 4,5:1. Cores de status devem ter pares `container` e `onContainer`.

### 3.3 Espaçamento

Preservar a escala base existente e formalizar usos:

- `spaceInlineTight`: 4;
- `spaceInline`: 8;
- `spaceControl`: 12;
- `spaceCard`: 16;
- `spaceGroup`: 24;
- `spaceSection`: 32;
- `spaceHero`: 48;
- `spaceCanvas`: 64, apenas large.

Valores 40 podem existir somente como composição responsiva de `spaceGroup + spaceCard`, não como novo degrau global. Valores 2 e 5 ficam restritos a detalhes ópticos como handle e separação de título/subtítulo.

### 3.4 Raios e elevação

| Token | Valor | Uso |
|---|---:|---|
| `radiusControl` | 12 | input, controle pequeno |
| `radiusParent` | 16 | cards e painéis Parent |
| `radiusKids` | 24 | cards e ações principais Kids |
| `radiusHero` | 28 | mascote, destaque e empty state Kids |
| `radiusSheet` | 28 no topo | bottom sheet compact |
| `radiusDialog` | 24 | dialog em tablet |
| `radiusPill` | total | chip, badge e saldo |

Elevação deve ser rara: nível 0 para canvas/listas, nível 1 para card interativo/destaque, nível 2 para navegação/modal e nível 3 somente para ação flutuante ou feedback transitório. Bordas e sombras não devem ser usadas juntas por padrão.

### 3.5 Superfícies e agrupamentos

Criar papéis distintos:

- **Canvas:** página, sem borda.
- **Section:** agrupamento por título, espaço e eventualmente divisor; sem container obrigatório.
- **List surface:** uma superfície única contendo várias linhas e divisores.
- **Interactive row:** altura mínima, leading, conteúdo, metadata e trailing previsíveis.
- **Highlight card:** apenas para próxima ação, resumo importante ou decisão pendente.
- **Inset surface:** fundo tonal sem sombra para progresso, explicação ou observação.
- **Empty state:** ícone/mascote, título, texto e ação opcional; sem parecer item acionável quando não é.

Regra: se a borda do bloco não comunica clique, seleção, elevação ou separação indispensável, remover o container e usar espaço/divisor.

### 3.6 Botões

- **Primary:** uma por região de decisão; 56 de altura em Kids e 48 em Parent.
- **Secondary:** contorno ou tonal, nunca com o mesmo peso da primary.
- **Tertiary:** texto/ícone para ações auxiliares.
- **Destructive:** vermelho somente no momento de decisão; arquivar em lista deve preferir menu ou ação secundária, não ícone vermelho permanente.
- **Icon button:** mínimo 48; 56 para ação prioritária Kids.
- Labels em w600 Fredoka; no OpenDyslexic, w700.
- Estado disabled deve manter legibilidade; loading preserva largura; foco visível de pelo menos 2 px.

### 3.7 Chips e badges

- Chip é filtro ou escolha; badge é estado e não deve parecer clicável.
- Parent filter chip: mínimo 44 visual dentro de alvo de 48, label 14/600.
- Kids choice chip: mínimo 48 visual, label 16/600 e ícone/emoji opcional.
- Seleção usa fundo tonal + texto de alto contraste; não depende apenas da borda ou da cor.
- Contadores de navegação devem ter label acessível e não deslocar o ícone.

### 3.8 Navegação

- **Kids:** manter navegação inferior nos quatro breakpoints. Quatro destinos, labels estáveis e a memória motora favorecem a criança. No tablet, centralizar o conteúdo interno da barra em vez de esticar os destinos indefinidamente.
- **Parent compact/medium:** manter navegação inferior.
- **Parent expanded/large:** usar rail lateral com os mesmos cinco índices e o mesmo `IndexedStack`; isso é uma troca visual do chrome, não de fluxo ou roteamento. Labels sempre visíveis em large e opcionais/compactas em expanded conforme largura útil.
- Troca de perfil permanece no topo e deve continuar protegida por PIN/biometria quando aplicável.

### 3.9 Modais, sheets e dialogs

- compact: bottom sheet para tarefas curtas e médias;
- medium: dialog para formulários focados; sheet somente quando o gesto de origem/contexto for importante;
- expanded/large: dialog central com 600–640 de largura; formulários longos podem usar 720, mantendo ações visíveis;
- confirmação destrutiva: dialog curto em todas as classes, nunca sheet longa;
- detalhes de missão/mimo: 520 compactado no tablet, sem card aninhado para repetir a superfície;
- formulários preservam scroll, teclado, safe area e ações fixas quando o conteúdo exceder a altura.

`ZeniAdaptiveModal` deve ser o único ponto de decisão de apresentação.

### 3.10 Touch targets e acessibilidade

- mínimo universal: 48×48;
- ação principal Kids: 56×56 ou 56 de altura;
- espaçamento mínimo entre alvos independentes: 8;
- nenhum ícone acionável de 44 como padrão;
- layout deve suportar escala de texto 1,35 sem truncar a ação principal;
- OpenDyslexic deve usar apenas 400/700, maior line-height e largura de linha mais curta;
- não usar emoji como único indicador de estado;
- manter `Semantics`, TTS, reduce motion e feedback háptico já existentes.

## 4. Zeni Kids

### 4.1 Princípios

- Uma pergunta por tela: “o que eu faço agora?”
- Uma ação visual dominante por estado.
- Mascote como guia contextual, não decoração repetida.
- Elementos grandes apenas quando carregam prioridade, não por ser tablet.
- Pouco texto, sentenças diretas e verbos concretos.
- Progresso e estrelas são visíveis, mas não competem com a missão atual.
- Estados de espera devem transmitir calma, não falha.

### 4.2 Expressão

- superfícies mais arredondadas e fundos tonais leves;
- mascote e avatar podem atravessar visualmente a grade, sem criar nova camada de card;
- emoji/ilustração em escala `support`, `feature` e `hero`, evitando valores locais por widget;
- cores secundárias — roxo, céu, rosa e amarelo — reservadas a categorias e feedback, nunca distribuídas aleatoriamente;
- motion curto e intencional em conclusão, preservando `disableAnimations`.

### 4.3 Densidade e hierarquia

- conteúdo prioritário com 24–32 de separação;
- listas secundárias agrupadas em uma superfície com divisores;
- metadata mínima e em linguagem natural;
- saldo persistente no header, mas visualmente menor que a missão atual;
- em tablets, usar espaço para relações lado a lado, não para inflar todos os controles.

## 5. Zeni Parent

### 5.1 Princípios

- Priorizar decisão, comparação e varredura rápida.
- Separar “precisa de mim agora” de “cadastro e manutenção”.
- Reduzir emojis grandes; usar avatar/emoji como identificador, não protagonista.
- Metadados alinhados e previsíveis.
- Ações frequentes visíveis; ações destrutivas ou raras em overflow/contexto.
- Uma superfície de lista por seção em vez de card por registro.

### 5.2 Expressão

- raio 16, sombra rara e bordas discretas;
- títulos w600 ou w700, corpo w400/500;
- verde como seleção/ação, não como cor de todo texto acionável;
- métricas podem usar cards, desde que cada card represente uma unidade comparável;
- estados pendentes ganham faixa tonal ou ícone de status, sem peso tipográfico excessivo.

### 5.3 Densidade e hierarquia

- linhas de 64–72 em listas comuns;
- linhas de 80–88 quando há duas linhas de metadata ou seleção em lote;
- seções separadas por 32, itens por divisor de 1;
- cabeçalho e filtros podem permanecer visíveis em listas longas no tablet;
- ação de criar missão/mimo continua disponível no shell, adaptada ao rail em telas largas.

## 6. Tipografia semântica

### 6.1 Escala Fredoka

Tamanhos em logical pixels. As variações entre classes são discretas e concentradas em títulos; corpo e controles não crescem automaticamente.

| Papel | Compact | Medium | Expanded | Large | Peso | Altura |
|---|---:|---:|---:|---:|---:|---:|
| `display` | 32 | 36 | 40 | 40 | 700 | 1,08–1,12 |
| `pageTitle` | 28 | 30 | 32 | 32 | 700 | 1,15 |
| `sectionTitle` | 22 | 22 | 24 | 24 | 600 | 1,22 |
| `cardTitle` | 18 | 18 | 18 | 18 | 600 | 1,28 |
| `body` | 16 | 16 | 16 | 16 | 400/500 | 1,45 |
| `metadata` | 14 | 14 | 14 | 14 | 400 | 1,40 |
| `button` | 16 | 16 | 16 | 16 | 600 | 1,20 |
| `chip` | 14 | 14 | 14 | 14 | 600 | 1,20 |

Regras:

- `display` é reservado a momentos de identidade Kids, onboarding e números hero; Parent usa `pageTitle` na maioria das telas;
- `pageTitle` aparece uma vez por página;
- `sectionTitle` não compete com a ação principal;
- `cardTitle` serve tanto a highlight card quanto a linha de lista com maior ênfase;
- valores numéricos podem usar tabular figures se a fonte/plataforma suportar;
- w800/w900 deixam de fazer parte do vocabulário.

### 6.2 OpenDyslexic

Mapeamento específico, sem herdar pesos inexistentes:

- `display`, `pageTitle`, `sectionTitle`, `cardTitle`, `button` e `chip`: w700;
- `body` e `metadata`: w400;
- acrescentar aproximadamente 0,05 à altura de linha dos estilos de leitura;
- limitar blocos de texto a cerca de 55–65 caracteres por linha;
- evitar all caps, itálico decorativo e truncamento em títulos importantes.

O text scale do sistema continua aplicado depois da seleção da escala semântica.

## 7. Regras de tablet e largura

### 7.1 Larguras de conteúdo

| Frame | Compact | Medium | Expanded | Large |
|---|---:|---:|---:|---:|
| `focus` | fluido | 560 | 640–680 | 720 |
| `main` | fluido | 760 | 928 | 1120 |
| `dashboard` | fluido | 760 | 960 | 1200 |

Padding horizontal recomendado: 20 em compact, 32 em medium, 48 em expanded e 64 em large. Vertical: 24/32/40/48 para início de página e 32/32/40/48 entre seções, escolhendo o papel e não o widget.

### 7.2 Colunas e grid

- compact: uma coluna;
- medium: uma coluna para fluxos focados; grid de duas colunas somente para itens independentes com mínimo de 280–320;
- expanded: duas colunas quando há relação clara mestre/detalhe, prioridade/secundário ou grupos independentes; listas de leitura podem continuar em uma coluna limitada;
- large: duas colunas como padrão para dashboards; três colunas apenas para cards homogêneos e curtos; nunca três colunas para formulários ou missões com texto variável.

### 7.3 Viewports obrigatórios

**390×844 — compact**

- conteúdo útil aproximado: 350 com padding 20;
- navegação inferior;
- uma coluna;
- sheets de largura total;
- ação prioritária Kids com 56 de altura;
- cabeçalhos curtos, sem duplicar título do shell e título da página.

**1024×1366 — expanded portrait**

- `main` usa 928; `dashboard`, 960;
- Parent usa rail; Kids mantém bottom nav;
- duas colunas somente nos blocos que ganham compreensão com proximidade;
- modais como dialogs de 600;
- Child Home: resumo lado a lado e sequência de ação preservada;
- Parent Missions: pendências e catálogo podem coexistir em colunas, com filtros compartilhados no topo.

**1366×1024 — large landscape**

- `main` usa 1120; `dashboard`, 1200;
- Parent rail sempre rotulado;
- Child bottom nav com destinos centralizados;
- dois painéis para Parent; até três colunas apenas para métricas/cards homogêneos;
- modais de 640, excepcionalmente 720 para formulário longo;
- evitar cards esticados: limitar largura de linha e preencher espaço com estrutura, não padding gigante.

### 7.4 Comportamento de cards e modais

- cards não crescem em altura proporcionalmente à tela;
- conteúdo textual mantém tamanho e largura de linha; espaço adicional cria colunas ou margens;
- listas longas têm uma superfície contínua;
- dialogs não ultrapassam 90% da altura e mantêm ações acessíveis;
- sheets compactas respeitam teclado e safe area;
- nenhuma tela cria breakpoint paralelo ou consulta largura para regras fora das quatro classes.

## 8. Piloto A — Child Home

### 8.1 Papel

É a referência visual do Zeni Kids e deve responder imediatamente: quem sou, como está meu dia e qual é a próxima ação.

### 8.2 Estrutura e hierarquia

1. **Identity bar:** avatar/nome, troca de perfil e saldo; compacto, persistente e secundário.
2. **Greeting:** “Oi, {nome}” como `pageTitle`; subtítulo curto apenas quando acrescentar contexto.
3. **Companion stage:** mascote + mensagem contextual em `surfaceSubtle`, sem sombra. O mascote comunica o estado já calculado.
4. **Now:** highlight card da missão atual, com emoji, título, estrelas e CTA explícita. É a única ação dominante.
5. **Day progress:** progresso, concluídas e aguardando aprovação; informativo, não botão.
6. **Later:** uma list surface com até três missões e divisores.
7. **Waiting:** lista tonal discreta, abaixo de ações pendentes.
8. **Reward progress:** teaser secundário para o mimo, depois do fluxo do dia.

Aniversário e pedido de mimo pendente continuam condicionais e preservam sua lógica, mas entram como banners tonais compactos, não novos cards equivalentes à missão atual.

### 8.3 Tipografia

- greeting: `pageTitle`;
- fala do mascote: `cardTitle`, uma ou duas linhas;
- “Agora”, “Depois” e “Aguardando”: `sectionTitle`;
- título da missão atual: `sectionTitle` no tablet, `cardTitle` no phone;
- metadata/estado: `metadata`;
- CTA: `button`.

### 8.4 Phone — 390×844

- uma coluna;
- greeting → mascote → missão atual → progresso → depois → espera → mimo;
- companion compacto, mascote entre 80 e 96, sem aumentar o bloco além do necessário;
- missão atual pode usar CTA textual “Ver missão” ou affordance equivalente dentro do card; alvo total mínimo 56;
- “Depois” usa linhas, não cards individuais;
- reduzir a repetição atual entre “Oi”, mensagem do mascote e “Seu dia” quando dizem a mesma coisa.

### 8.5 Tablet portrait — 1024×1366

- frame `main` de 928;
- greeting em toda a largura;
- faixa superior em 60/40: companion à esquerda, day progress à direita;
- missão atual continua abaixo e em largura suficiente para ser a ação dominante;
- bloco inferior pode usar 60/40: “Depois” à esquerda, espera/mimo à direita;
- não aumentar todos os paddings para 32–40 nem o mascote automaticamente para 148.

### 8.6 Tablet landscape — 1366×1024

- frame `main` de 1120;
- coluna principal de aproximadamente 680–720 para greeting, companion e missão atual;
- coluna secundária de aproximadamente 360–400 para day progress, waiting e reward progress;
- “Depois” permanece ligado à missão atual na coluna principal;
- manter navegação inferior centralizada.

### 8.7 Remover ou reduzir

- sombras e bordas simultâneas em todos os cards;
- card separado por item em “Aguardando aprovação”;
- labels repetidas que descrevem o mesmo estado;
- aumento de escala por `isTablet` para todo título/emoji/padding;
- saldo ou progresso de mimo competindo com “Agora”.

### 8.8 Ganhar destaque

- missão de agora;
- estado do mascote;
- conclusão/espera claramente distintas;
- CTA e alvo de toque;
- progresso do dia como orientação, não como segunda ação.

## 9. Piloto B — Parent Missions

### 9.1 Papel

É a referência visual do Zeni Parent e deve separar trabalho pendente de manutenção das missões.

### 9.2 Estrutura e hierarquia

1. **Page header:** `pageTitle` “Missões”, resumo curto e ação “Nova missão” integrada ao chrome existente.
2. **Filters:** chips por criança em uma linha estável; no tablet, alinhados ao título/controles.
3. **Pending approvals:** prioridade operacional, contador, seleção em lote e linhas de aprovação.
4. **Active missions:** lista escaneável com criança, período, estrelas e ações.
5. **Suggestions:** ação terciária/banner compacto próximo do catálogo, não antes das pendências.
6. **Archived:** disclosure secundário no final, sem ocupar peso visual quando fechado.

### 9.3 Tipografia

- página: `pageTitle`, não `display`;
- seção: `sectionTitle`;
- missão: `cardTitle`;
- criança/período/estrelas: `metadata` com separação visual consistente;
- ações: `button`/`chip`, sem w900;
- contador pendente: badge semântico, não título bold adicional.

### 9.4 Cards e listas

- pendências: uma highlight surface com rows de 80–88 e divisores;
- ativas: uma list surface com rows de 64–72;
- seleção usa checkbox, fundo selecionado e barra de lote fixa no contexto da seção;
- editar como ação rápida; arquivar em menu/ação secundária para reduzir vermelho e ruído;
- metadata pode usar ícones discretos ou colunas, mas deve continuar legível por leitor de tela;
- empty state fica dentro da seção como composição aberta, sem sombra.

### 9.5 Phone — 390×844

- uma coluna;
- header e filtros → pendências → ativas → sugestões → arquivadas;
- CTA de criar permanece FAB conforme shell atual;
- ações de item cabem em menu ou detalhe para não comprimir título;
- barra de lote permanece visível acima da navegação quando ativa;
- substituir o padding fixo final de 96 por inset derivado do shell/FAB.

### 9.6 Tablet portrait — 1024×1366

- frame `dashboard` ou `main` com 928–960;
- rail Parent libera altura e reduz dispersão da navegação;
- header e filtros em toda a largura;
- duas colunas: pendências 360–400 à esquerda; ativas flexível à direita;
- quando não houver pendências, ativas ocupam a largura e o empty state não reserva uma coluna vazia;
- dialog para aprovação e edição.

### 9.7 Tablet landscape — 1366×1024

- frame de 1120–1200 após o rail;
- painel de pendências de aproximadamente 400–440 e catálogo de 640–720;
- títulos de seção e controles podem ficar sticky dentro do painel;
- ações de lote ficam no painel de pendências, sem ocupar o catálogo;
- archived abre dentro do painel de catálogo ou em seção inferior de largura controlada.

### 9.8 Remover ou reduzir

- `displayLarge` para um título operacional;
- aumento local de 12% via `ParentMissionTypography`;
- um `ZeniCard` por missão ativa;
- dois icon buttons coloridos permanentemente em cada linha;
- sugestões antes do trabalho pendente;
- bordas e sombras no empty state;
- bottom sheet em tablet para aprovação.

### 9.9 Ganhar destaque

- número de aprovações;
- identidade da criança;
- título e estado da missão;
- seleção em lote e confirmação;
- ação de criar missão no chrome do modo Parent.

## 10. Ordem de rollout

### 10.1 Fase 0 — fundação

Antes das telas piloto:

- cores semânticas claro/escuro;
- tipografia semântica Fredoka/OpenDyslexic;
- spacing, raios, elevação e touch targets;
- page header, section, list surface, row, highlight card, empty state, chips e botões;
- shell responsivo e modal adaptativo;
- testes nos três viewports e com text scale 1,35.

### 10.2 Modo criança

| Ordem | Tela | Tratamento |
|---:|---|---|
| 1 | Profile choice | Redesign específico: porta de entrada Kids/Parent, grid real no tablet |
| 2 | Child Home | Piloto e redesign específico completo |
| 3 | Child Missions | Redesign específico baseado em lista Kids e grupos de horário |
| 4 | Mission detail/completion | Redesign específico; ação única, sheet/dialog adaptativo e feedback |
| 5 | Rewards | Redesign específico de catálogo, disponibilidade e pedido pendente |
| 6 | Balance | Herda DS em grande parte; precisa de hero de saldo e lista de ledger, sem nova regra |

### 10.3 Modo responsável

| Ordem | Tela | Tratamento |
|---:|---|---|
| 1 | Parent Home | Redesign específico de dashboard e prioridade operacional |
| 2 | Missions | Piloto e redesign específico completo |
| 3 | Rewards | Herda o padrão de Missions; adaptação específica de custo/pedido |
| 4 | Family | Herda DS; redesign moderado para listas, resumo e gestão em tablet |
| 5 | Settings | Predominantemente herança de DS; reorganização em seções e largura de formulário |

### 10.4 Telas por nível de esforço

**Redesign específico:** Profile Choice, Child Home, Child Missions, mission detail/completion, Child Rewards, Parent Home e Parent Missions.

**Herança com adaptação localizada:** Balance, Parent Rewards, Family, Settings, onboarding, auth/PIN, smart suggestions e forms de missão/mimo/criança.

**Herança quase direta:** popups de feedback, confirmações simples, inputs, switches, badges e estados de loading/error, depois de atualizados no Core DS.

## 11. Riscos de escopo e controles

| Risco | Controle |
|---|---|
| Redesign visual alterar prioridade funcional | Congelar fluxos e callbacks antes de cada tela; comparar estados e ações |
| Migrar modal alterar resultado ou cancelamento | Manter contratos de retorno e apenas trocar apresentação |
| Rail alterar navegação/estado | Preservar índices, `IndexedStack` e callbacks do shell |
| Nova composição quebrar offline-first | UI lê e aciona os mesmos controllers/repositories; sem chamadas remotas novas |
| Saldo visual divergir da fonte operacional | Toda exibição continua usando `ChildProfile.starBalance`; ledger permanece histórico |
| Aprovação/restore/archive perder segurança | Reutilizar as confirmações, PIN/biometria e guards existentes |
| OpenDyslexic e escala 1,35 causarem overflow | Testes de layout por viewport, sem truncar CTA/título essencial |
| Contraste regredir no dark mode | Tokens semânticos por tema e testes de contraste |
| V2 conviver indefinidamente com estilos locais | Migrar por vertical e remover overrides após adoção, não criar uma terceira camada |
| Tablet gerar layouts vazios | Colunas condicionais por conteúdo e min-width, dentro dos breakpoints existentes |
| Emojis variarem por plataforma | Tratar como apoio; nunca como único estado ou instrução |
| Alterações locais atuais serem sobrescritas | Inventariar e integrar conscientemente antes de implementação |

Fora de escopo: features novas, gamificação nova, premium, realtime, merge, IA, regras de saldo, regras de missão/mimo, sync, restore, autenticação, segurança, arquitetura de dados ou navegação funcional nova.

## 12. Arquivos e tokens provavelmente alterados na implementação futura

### 12.1 Core existente

- `lib/core/theme/zeni_theme.dart`: papéis do `ColorScheme`, temas de componentes e modos Kids/Parent;
- `lib/core/theme/zeni_typography.dart`: escala semântica e mapeamento OpenDyslexic;
- `lib/core/theme/zeni_colors.dart`: paleta semântica claro/escuro;
- `lib/core/theme/zeni_spacing.dart`: aliases de uso;
- `lib/core/theme/zeni_radius.dart`: raios por papel;
- `lib/core/theme/zeni_shadows.dart`: níveis de elevação e dark mode;
- `lib/core/layout/zeni_responsive.dart`: padding, frames, grid, modal e chrome adaptativo, sem novos breakpoints;
- `lib/core/widgets/base/zeni_card.dart`: separar highlight/surface de lista;
- `lib/core/widgets/base/zeni_primary_button.dart`;
- `lib/core/widgets/base/zeni_secondary_button.dart`;
- `lib/core/widgets/base/zeni_text_button.dart`;
- `lib/core/widgets/base/zeni_icon_action_button.dart`;
- `lib/core/widgets/base/status_badge.dart`;
- `lib/core/widgets/base/zeni_balance_pill.dart`;
- `lib/core/widgets/layout/zeni_bottom_nav_bar.dart`;
- `lib/core/widgets/layout/zeni_top_bar.dart`;
- `lib/core/widgets/layout/zeni_modal_sheet_container.dart`;
- componentes de feedback e inputs para consumir os novos tokens.

Prováveis novas primitivas, se a implementação confirmar a necessidade:

- `ZeniSection` / `ZeniSectionHeader`;
- `ZeniListSurface` / `ZeniListRow`;
- `ZeniHighlightCard`;
- `ZeniEmptyState`;
- `ZeniAdaptiveNavigation`;
- `ZeniModalPresenter` como fachada única de sheet/dialog.

### 12.2 Pilotos

- `lib/features/child/presentation/widgets/child_home_tab.dart`;
- widgets de apoio de Child Home que permanecerem em uso;
- `lib/features/child/presentation/pages/child_shell_page.dart`;
- `lib/features/parent/presentation/widgets/parent_missions_tab.dart`;
- `lib/features/parent/presentation/widgets/mission_approval_card.dart`;
- `lib/features/parent/presentation/widgets/parent_mission_card.dart`;
- `lib/features/parent/presentation/widgets/parent_child_filter_chips.dart`;
- `lib/features/parent/presentation/pages/parent_shell_page.dart`.

`parent_mission_typography.dart` tende a ser removido depois que a escala semântica global absorver seu papel.

### 12.3 Rollout posterior

- Profile Choice, Child Missions, Child Rewards e Balance;
- Parent Home, Rewards, Family e Settings;
- detalhes/forms de missão, recompensa e criança;
- auth, onboarding e smart suggestions para herança consistente.

Não há motivo visual para alterar `ZeniAppStateController`, modelos, domínio, repositories, providers de sync/auth/balance, ledger, restore ou regras de missão/mimo.

## 13. Critérios de aceite antes de implementar o rollout

O piloto só deve ser considerado validado quando:

- Child Home deixa evidente a próxima ação em menos de um olhar;
- Parent Missions separa pendências de manutenção e permite escanear criança, missão, período e estrelas;
- os três viewports obrigatórios usam os mesmos quatro breakpoints atuais;
- tablet reorganiza, não apenas amplia;
- nenhum texto normal depende de verde com contraste insuficiente;
- não há w800/w900 nem peso inexistente no caminho dos pilotos;
- OpenDyslexic e escala 1,35 não causam overflow funcional;
- alvos têm no mínimo 48 e ações prioritárias Kids, 56;
- modais são sheet no phone e dialog no tablet conforme o padrão;
- fluxos, estado, saldo, ledger, auth, sync, restore e segurança permanecem inalterados;
- testes funcionais existentes continuam descrevendo o mesmo comportamento, ainda que testes puramente visuais precisem ser atualizados.

## Decisão recomendada

Prosseguir com uma fase curta de fundação seguida dos dois pilotos, nesta ordem: **Core DS V2 → Child Home → Parent Missions → validação nos três viewports → rollout por modo**. Evitar redesenhar todas as telas em paralelo antes de os pilotos estabilizarem tipografia, superfície, lista, modal e navegação.
