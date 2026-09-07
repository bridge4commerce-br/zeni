# Zeni V2 — Especificação de Produto e Técnica
## Sugerir Missões v1.0

**Status:** pronto para implementação  
**Base:** Zeni Smart Content Master v1.0  
**Escopo:** sugestão local/offline para responsáveis  
**IA online:** fora desta versão  

---

# 1. Objetivo

Permitir que o responsável receba sugestões relevantes de missões e rotinas para uma criança, usando a biblioteca local aprovada do Zeni.

A função deve responder de forma simples à pergunta:

> “O que posso propor para esta criança agora?”

O sistema usa:

- idade;
- contexto;
- objetivo escolhido pela família;
- preferências da família;
- missões já existentes;
- sugestões recusadas recentemente;
- configuração de apoio da criança;
- idioma ativo.

A função deve funcionar:

- sem login;
- sem internet;
- sem Supabase;
- sem IA;
- sem alterar saldo, ledger, sync ou restore.

---

# 2. Princípios obrigatórios

1. **Local first**
   - toda sugestão da v1 vem da biblioteca local.

2. **Responsável sempre decide**
   - nenhuma missão ou rotina é criada automaticamente.

3. **Poucas sugestões**
   - mostrar de 3 a 5 opções relevantes;
   - nunca apresentar a biblioteca inteira como primeira experiência.

4. **Sem diagnóstico**
   - o Zeni adapta forma de apresentação;
   - não usa “modo TDAH”, “modo autismo” ou equivalente.

5. **Preferência da família > país**
   - idioma e cultura ajudam no ponto de partida;
   - escolhas reais da família têm maior peso.

6. **Missão é atômica**
   - uma ação pequena e clara.

7. **Rotina é composta**
   - sequência editável de missões.

8. **Estrelas são opcionais**
   - autocuidado básico pode ter 0 estrelas.

---

# 3. Onde a função aparece

## Entrada principal

No fluxo atual de criação de missão do responsável:

**Nova missão**

- Criar manualmente
- ✨ Sugerir com o Zeni

### Recomendação de UI

“Sugerir com o Zeni” deve ser uma ação clara, mas não substituir a criação manual.

Exemplo conceitual:

> **Nova missão**  
> Crie do seu jeito ou deixe o Zeni ajudar.

[ ✨ Sugerir com o Zeni ]

[ Criar manualmente ]

---

# 4. Fluxo principal

```text
Nova missão
    ↓
Sugerir com o Zeni
    ↓
Escolher criança
    ↓
Escolher objetivo
    ↓
(opcional) escolher contexto
    ↓
ranking local
    ↓
3–5 sugestões
    ↓
escolher missão ou rotina
    ↓
revisar / editar
    ↓
confirmar
    ↓
criar usando fluxo normal do Zeni
```

---

# 5. Etapa 1 — Para quem?

## Regra

Se houver apenas uma criança ativa:

- pular a tela;
- usar essa criança automaticamente.

Se houver duas ou mais:

> **Para quem é a missão?**

Mostrar os perfis infantis já existentes.

Nenhum novo cadastro ocorre aqui.

---

# 6. Etapa 2 — O que você quer trabalhar?

Pergunta:

> **O que você quer ajudar a desenvolver?**

Mostrar no máximo 6 opções principais.

### Opções

1. **Autonomia**
2. **Organização**
3. **Estudos**
4. **Rotina**
5. **Participação em casa**
6. **Vida prática**

### Responsabilidade digital

Só aparece se:

- a família tiver habilitado responsabilidade digital; ou
- houver missões digitais já utilizadas para aquela criança.

### Comportamento

A escolha não filtra de forma rígida.

Ela dá peso maior às missões relacionadas.

Isso permite que uma boa sugestão de outro domínio ainda apareça se for muito relevante ao contexto.

---

# 7. Etapa 3 — Em qual momento?

Essa etapa deve ser curta e opcional.

Pergunta:

> **Tem algum momento específico?**

Sugestões de contexto:

- Ao acordar
- Antes da escola
- Depois da escola
- Hora da tarefa
- Antes da refeição
- Depois da refeição
- Antes de sair
- Ao voltar para casa
- Hora de dormir
- Fim de semana
- Sem momento específico

## Regra

O Zeni pode destacar apenas contextos compatíveis com as missões da biblioteca.

Se o responsável escolher “Sem momento específico”, o ranking segue normalmente.

---

# 8. Tela de resultado

Título:

> **Sugestões para [nome da criança]**

Subtexto:

> Escolhi algumas ideias que combinam com o que você quer trabalhar.

Mostrar inicialmente **3 sugestões**.

Permitir:

> Ver mais sugestões

até o máximo de **5**.

Nunca carregar uma lista infinita.

---

# 9. Card de missão sugerida

Exemplo:

> 🎒 **Guardar a mochila ao chegar**  
> Ajuda a criar uma rotina de chegada e cuidar das próprias coisas.  
>
> Depois da escola · Autonomia  
> ⭐ Estrelas opcionais
>
> [ Usar esta missão ]

### Informações do card

Obrigatórias:

- título;
- descrição curta;
- contexto;
- principal benefício/habilidade;
- estrelas, quando relevante.

Não mostrar:

- carga cognitiva;
- tags técnicas;
- score;
- IDs;
- dados internos de ranking.

---

# 10. Card de rotina sugerida

Exemplo:

> ✨ **Rotina: Cheguei em casa**  
> Uma sequência simples para organizar a chegada.
>
> 5 etapas · Uma por vez
>
> [ Ver rotina ]

Ao abrir:

1. Guardar a mochila
2. Lavar as mãos
3. Levar a lancheira para a cozinha
4. Esvaziar a lancheira
5. Levar prato/copo para a pia

A família pode:

- remover etapas;
- reordenar;
- adicionar uma missão já existente;
- decidir estrelas;
- decidir aprovação;
- escolher checklist ou uma etapa por vez.

---

# 11. Tela de revisão — missão

Depois de tocar em “Usar esta missão”:

Abrir a tela de criação já existente com os campos preenchidos.

### Preencher automaticamente

- criança;
- título;
- descrição;
- estrelas sugeridas;
- aprovação padrão;
- contexto;
- categoria/domínio.

### O responsável pode alterar

Tudo o que já é permitido na criação manual.

### Regra crítica

A sugestão **não cria a missão**.

Só a confirmação final do responsável cria a missão no estado local.

---

# 12. Tela de revisão — rotina

Ao escolher uma rotina:

> **Personalize esta rotina**

Mostrar:

- nome da rotina;
- etapas;
- ordem;
- modo de apresentação;
- estrelas;
- aprovação.

## Opções

### Apresentação

- Uma etapa por vez
- Checklist

Padrão recomendado:

**Uma etapa por vez**

especialmente para rotinas de transição.

### Estrelas

- Sem estrelas
- Estrelas ao concluir a rotina
- Estrelas por etapa

O Zeni pode sugerir o modo, mas o responsável decide.

---

# 13. Estados especiais

## Sem sugestões

Evitar:

> Nenhuma missão encontrada.

Usar:

> **Não encontrei uma combinação boa agora.**
>
> Você pode escolher outro objetivo ou criar uma missão manualmente.

Ações:

- Mudar objetivo
- Criar manualmente

---

## Todas as sugestões já estão ativas

> **Vocês já estão trabalhando bastante nisso.**
>
> Posso buscar ideias de outro tipo.

---

## Offline

Não mostrar erro.

A função é local.

O `ZeniConnectivityPill` pode indicar que o app está offline normalmente.

Não deve existir mensagem:

> “Conecte-se para receber sugestões.”

---

# 14. Regras de ranking

## Filtros obrigatórios

Excluir:

1. missão fora da faixa etária;
2. domínio desativado pela família;
3. contexto claramente incompatível;
4. missão já ativa para a criança;
5. missão inadequada por requisito de supervisão no contexto atual.

---

## Pontuação sugerida

### +30
Prioridade escolhida pela família.

### +25
Contexto atual.

### +20
Habilidade que a família quer desenvolver.

### +10
Boa compatibilidade etária.

### +10
Ainda não sugerida recentemente.

### +5
Novidade controlada.

---

## Penalidades

### -30
Responsável descartou recentemente.

### -40
Exige supervisão e o contexto não é adequado.

### -100
Já existe como missão ativa equivalente.

---

# 15. Detecção de duplicidade

Não usar apenas título.

Primeiro critério:

`missionTemplateId`

Exemplo:

```text
take_plate_to_sink
```

Se uma missão criada pelo Smart Content mantiver esse ID de origem, a duplicidade é direta.

Para missões criadas manualmente:

usar comparação simples por:

- categoria;
- palavras-chave;
- criança;
- estado ativo.

Não implementar IA semântica nesta fase.

---

# 16. Histórico de sugestões

Salvar localmente apenas o necessário para melhorar ranking.

Exemplo conceitual:

```dart
SmartSuggestionHistory {
  childId,
  contentId,
  type, // mission | routine
  action, // accepted | rejected | viewed
  occurredAt,
}
```

Não precisa ir para Supabase nesta fase.

Pode permanecer local.

---

# 17. Contrato técnico

## SmartContentRepository

Responsabilidades:

- carregar assets;
- carregar metadados globais;
- carregar locale;
- unir pelo ID;
- disponibilizar missões e rotinas.

Interface conceitual:

```dart
abstract class SmartContentRepository {
  Future<List<SmartMissionTemplate>> getMissions(Locale locale);

  Future<List<SmartRoutineTemplate>> getRoutines(Locale locale);
}
```

---

# 18. SmartContentService

Responsável por:

- filtros;
- ranking;
- duplicidade;
- ordenação;
- limite de sugestões.

Interface conceitual:

```dart
class SmartContentService {
  Future<List<SmartSuggestion>> suggest({
    required ChildProfile child,
    required SmartSuggestionGoal goal,
    SmartSuggestionContext? context,
    required FamilySmartPreferences preferences,
    required List<Mission> activeMissions,
    required List<SmartSuggestionHistory> history,
    int limit = 5,
  });
}
```

---

# 19. Tipos principais

## SmartSuggestionGoal

```dart
enum SmartSuggestionGoal {
  autonomy,
  organization,
  study,
  routine,
  homeParticipation,
  lifeSkills,
  digital,
}
```

---

## SmartSuggestionContext

```dart
enum SmartSuggestionContext {
  morning,
  beforeSchool,
  afterSchool,
  homework,
  beforeMeal,
  afterMeal,
  beforeLeaving,
  arrival,
  bedtime,
  weekend,
  none,
}
```

---

# 20. SmartSuggestion

```dart
sealed class SmartSuggestion {
  const SmartSuggestion();
}
```

## MissionSuggestion

```dart
class MissionSuggestion extends SmartSuggestion {
  final SmartMissionTemplate mission;
  final int score;
}
```

## RoutineSuggestion

```dart
class RoutineSuggestion extends SmartSuggestion {
  final SmartRoutineTemplate routine;
  final int score;
}
```

O `score` é interno.

Nunca mostrar para o usuário.

---

# 21. MissionTemplate

Campos mínimos:

```dart
class SmartMissionTemplate {
  final String id;
  final String domain;
  final int ageMin;
  final int ageMax;

  final String title;
  final String description;
  final List<String> helpSteps;

  final int suggestedStars;
  final bool eligibleAsExtra;
  final bool requiresApprovalByDefault;

  final List<String> contexts;
  final List<String> skills;

  final SmartMissionSupport support;
}
```

---

# 22. RoutineTemplate

```dart
class SmartRoutineTemplate {
  final String id;
  final String title;
  final String description;

  final List<String> missionIds;

  final int ageMin;
  final int ageMax;

  final bool contextual;
}
```

---

# 23. Assets Flutter

Estrutura recomendada:

```text
assets/
  smart_content/
    global/
      missions.json
      routines.json

    locales/
      pt-BR.json
      en.json
      es.json
      fr.json
      de.json
      ja.json

    config/
      ranking_rules.json
      support_preferences.json
      family_config.json
```

Declarar no `pubspec.yaml`.

---

# 24. Localização

A biblioteca usa:

```text
ID global
+
texto do locale
```

Exemplo:

```text
take_plate_to_sink
```

PT-BR:

> Levar o prato para a pia

EN:

> Take your plate to the sink

DE:

> Teller zur Spüle bringen

JA:

> 食器をシンクへ運ぶ

O ID nunca muda.

---

# 25. Apoio adaptável

O motor pode usar as preferências da criança para decidir **como apresentar**, não qual diagnóstico ela possui.

Exemplo:

A mesma rotina pode aparecer como:

### Checklist

- guardar mochila
- lavar mãos
- guardar lancheira
- levar prato

ou:

### Uma etapa por vez

> Primeiro: guarde sua mochila.

Depois:

> Muito bem. Agora lave as mãos.

---

# 26. Autonomia progressiva

Preparar o modelo para:

```text
with_support
    ↓
reminder
    ↓
independent
```

Não é necessário automatizar a progressão na primeira implementação.

Na v1:

- guardar o campo;
- permitir uso futuro.

Não criar regras automáticas complexas agora.

---

# 27. Segurança

Missões com atenção especial devem respeitar:

- idade;
- supervisão;
- configuração familiar.

Exemplos:

- preparo de alimento;
- limpeza;
- descarte de lixo;
- atividades que possam envolver equipamentos.

A biblioteca pode sugerir:

> “Com ajuda de um responsável”

Não permitir que o sistema transforme missão supervisionada em missão autônoma automaticamente.

---

# 28. Relação com Missões Extras

Missões marcadas:

```text
eligibleAsExtra = true
```

podem futuramente aparecer em:

> **Missões Extras**

Mas “Sugerir com o Zeni” e “Missões Extras” são funções diferentes.

### Sugerir com o Zeni

O responsável procura uma ideia.

### Missões Extras

A criança vê oportunidades previamente permitidas pelo responsável.

Não misturar os dois fluxos nesta fase.

---

# 29. Relação com IA futura

A IA não entra nesta primeira implementação.

Fluxo futuro:

```text
Smart Content local
       ↓
encontrou boa resposta?
       ↓ sim
usar local

       ↓ não
IA online opcional
```

Exemplo futuro:

> “Quero uma missão para meu filho lembrar o aparelho dentário.”

Se não houver uma missão equivalente na biblioteca, o Zeni Copiloto poderá gerar uma sugestão.

Ainda assim:

- adulto revisa;
- adulto confirma;
- IA nunca cria diretamente;
- IA nunca altera saldo.

---

# 30. Testes mínimos

## Repository

- carrega os 94 IDs;
- carrega 26 rotinas;
- locale correto;
- fallback de locale;
- IDs iguais entre global/localizado.

## Service

- respeita idade;
- respeita contexto;
- não sugere missão ativa;
- respeita domínio desabilitado;
- aplica penalidade de rejeição;
- máximo de 5 resultados;
- funciona totalmente offline.

## UI

- uma criança → pula seletor;
- várias crianças → mostra perfis;
- rotina permite reordenar;
- missão abre criação pré-preenchida;
- sair antes de confirmar não cria nada;
- sem `SnackBar`;
- nenhuma dependência de Supabase.

---

# 31. Critério de conclusão da feature

“Sugerir com o Zeni” está pronto quando:

1. funciona sem internet;
2. usa a biblioteca v1.0;
3. respeita idioma;
4. filtra por idade;
5. considera objetivo/contexto;
6. evita duplicidade;
7. retorna no máximo 5 sugestões;
8. oferece missões e rotinas;
9. permite revisão;
10. só cria após confirmação;
11. não altera regras de saldo, ledger, auth, sync ou restore;
12. testes passam.

---

# 32. Ordem de implementação recomendada

## Fase A — infraestrutura
- adicionar assets;
- criar models;
- criar repository;
- testes de carregamento.

## Fase B — motor
- filtros;
- ranking;
- duplicidade;
- histórico local;
- testes unitários.

## Fase C — UX
- botão “Sugerir com o Zeni”;
- objetivo;
- contexto;
- resultados;
- revisão.

## Fase D — rotinas
- tela de rotina;
- remover etapas;
- reordenar;
- apresentação.

## Fase E — QA
- offline;
- idiomas;
- crianças de idades diferentes;
- duplicidade;
- back/cancel;
- regressão do fluxo manual.

---

# 33. Decisão final

A primeira versão de “Sugerir com o Zeni” deve ser percebida como inteligência útil, mas tecnicamente continuar simples, previsível e offline.

O valor não está em fazer o usuário conversar com uma IA.

O valor está em:

> **o Zeni conhecer boas opções, mostrar poucas ideias relevantes e ajudar o responsável a transformar uma intenção em uma missão prática em poucos segundos.**
