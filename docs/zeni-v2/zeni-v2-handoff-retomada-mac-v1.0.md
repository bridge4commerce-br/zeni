# Zeni V2 — Handoff para Retomada no Mac v1.0

> **Superseded:** este handoff registra uma etapa anterior do rollout V2. Para
> o contexto operacional atual, use `docs/context/zeni-context-current.md`.
> Smart Content e “Sugerir missões” não são próximos passos deste handoff.

**Data:** 2026-09-06  
**Status do projeto:** pré-beta interno maduro  
**Objetivo deste arquivo:** permitir retomar o projeto Flutter correto sem reabrir decisões já fechadas de arquitetura, UX e Smart Content.

---

## 1. Fonte de verdade

Ao retomar no Mac, usar nesta ordem:

1. `zeni-contexto-geral-aplicativo.md`
   - estado técnico consolidado do app;
   - regras offline-first;
   - estado local, auth opcional, Supabase, sync, ledger, restore, RLS e QA;
   - restrições que não podem ser quebradas.

2. `zeni-v2-base-conhecimento-v0.3.md`
   - decisões atuais de produto e experiência Zeni V2;
   - Design System;
   - modo criança e modo responsável;
   - mascote e motion;
   - benchmarks Joon / Greenlight / S’moresUp;
   - Missões Extras;
   - estratégia de IA;
   - Smart Content Master v1.0.

3. `zeni_smart_content_master_v1_0.zip`
   - pacote técnico oficial da biblioteca inteligente local;
   - metadados globais;
   - textos localizados;
   - regras de ranking;
   - configuração da família;
   - preferências de apoio;
   - schemas e validação.

4. `zeni_smart_content_master_v1_0.xlsx`
   - mestre editorial e de QA;
   - 94 missões aprovadas;
   - 26 rotinas aprovadas;
   - comparação de idiomas;
   - decisões e validações.

### Materiais históricos

Não usar como fonte principal de implementação:

- `zeni-v2-base-conhecimento-v0.2.md`;
- `zeni_smart_content_v0_2.zip`;
- `zeni_modelo_inteligente_mestre_ptbr_v1.xlsx`;
- `zeni_validacao_modelo_inteligente_ptbr.xlsx`.

Esses arquivos podem ser preservados somente como histórico de evolução.

---

## 2. Regras técnicas que permanecem obrigatórias

O Zeni deve continuar:

- funcionando sem login;
- funcionando sem internet;
- funcionando sem Supabase;
- com estado operacional principal local;
- usando `ChildProfile.starBalance` local como fonte operacional da UX;
- tratando Supabase como camada progressiva;
- sem merge automático nesta fase;
- sem realtime amplo nesta fase;
- sem restaurar streak;
- sem `SnackBar` / `ScaffoldMessenger`;
- com logout preservando dados locais;
- com wipe local sem apagar nuvem;
- sem exclusão remota disponível na UI atual;
- sem copiar saldo remoto diretamente para o app.

Não alterar ledger, sync, restore, auth ou saldo para implementar Zeni V2 ou Smart Content.

---

## 3. Estado fechado do Smart Content v1.0

A primeira biblioteca oficial está congelada com:

- **94 missões aprovadas**;
- **26 rotinas aprovadas**;
  - 20 principais;
  - 6 contextuais;
- **8 domínios**;
- **6 idiomas**:
  - `pt-BR`;
  - `en`;
  - `es`;
  - `fr`;
  - `de`;
  - `ja`.

### Estrutura

`global metadata + localized text`

Os IDs de missão e rotina da v1.0 são estáveis e não devem ser renomeados durante a integração.

### Princípios

- conteúdo local primeiro;
- Smart Content funciona offline;
- até 5 sugestões relevantes por vez;
- família configura prioridades;
- preferências reais da família valem mais do que suposições por país;
- idioma/localização adapta texto e tom;
- apoio é adaptado por necessidade, não por diagnóstico;
- não existe “modo TDAH” ou “modo autismo”;
- estrelas podem ser zero em responsabilidades básicas;
- rotina é sequência editável de missões atômicas;
- caminho de autonomia: `com apoio → lembrete → independente`.

### Apoios configuráveis

- uma etapa por vez;
- apoio visual;
- TTS;
- timer opcional;
- aviso de transição;
- repetição de instrução;
- ordem fixa ou flexível;
- intensidade de celebração;
- redução gradual de apoio.

---

## 4. IA — decisão atual

Não começar implementando IA.

Arquitetura definida:

### Camada 1 — Smart Content local

- offline;
- custo zero;
- conteúdo estruturado;
- regras de filtro e ranking;
- sugestões previsíveis;
- textos localizados.

### Camada 2 — IA online futura

Somente para fallback ou personalização que a biblioteca local não resolva.

A IA:

- passa por backend/gateway;
- nunca expõe chave de provedor no Flutter;
- não altera saldo;
- não altera ledger;
- não aprova missão;
- não cria recompensa autonomamente;
- não substitui decisão do responsável.

Regra:

`local first → AI only when needed`

---

## 5. Zeni V2 — decisões de experiência já fechadas

### Base visual

- Material 3 como fundação técnica;
- Zeni Core DS;
- Zeni Kids;
- Zeni Parent;
- sem redesign simultâneo de todas as telas.

### Mascote

Usar `ZeniMascot(state: ...)` com arte estática + motion nativo Flutter.

Estados previstos:

- idle;
- encourage;
- waitingApproval;
- celebrating;
- sleeping;
- thinking;
- rewardClose;
- achievement.

Não usar Rive agora.

### Criança

A Home deve responder rapidamente:

1. o que eu tenho para fazer;
2. quantas estrelas tenho;
3. quanto falta para meu mimo.

A criança não acessa áreas do responsável.

### Responsável

A Home concentra pendências em **“Precisa de você”**.

Criar missão básica deve continuar rápido, com opções avançadas escondidas.

### Conectividade

Usar `ZeniConnectivityPill`.

Offline não é erro: o núcleo continua funcionando.

### Missões Extras

Fazem parte da Zeni V2 e devem respeitar as mesmas regras locais de missão, estrelas e aprovação.

---

## 6. Próximo trabalho de produto antes do código

Antes de integrar o Smart Content no Flutter, fechar a especificação de UX e contrato técnico de:

# **Sugerir missões**

Fluxo esperado:

`responsável → Sugerir com o Zeni → criança → objetivo/contexto → ranking local → 3–5 sugestões → revisar/editar → confirmar → criar missão normal`

Também deve permitir sugerir uma rotina quando ela for mais adequada do que uma missão isolada.

A sugestão nunca é salva automaticamente.

---

## 7. Próxima integração técnica prevista

Quando a UX de “Sugerir missões” estiver fechada, integrar no Flutter com uma camada dedicada, sem tocar no domínio financeiro/operacional existente.

Componentes conceituais:

- `SmartContentRepository`;
- `SmartContentService`;
- `MissionSuggestion`;
- `RoutineTemplate`.

Fluxo técnico:

`idade + contexto + preferências da família`

→ filtros locais  
→ ranking  
→ máximo de 5 sugestões  
→ responsável revisa/edita  
→ usa o fluxo normal já existente de criação de missão.

O serviço deve ler os assets do pacote `zeni_smart_content_master_v1_0` e unir metadados globais ao locale ativo pelo mesmo `id`.

---

## 8. Regra de retomada no Mac

Não começar alterando código.

Primeiro:

1. localizar o projeto Flutter atual/correto;
2. verificar o estado do Git;
3. confirmar branch e repositório remoto corretos;
4. preservar o bundle ID dos apps;
5. confirmar baseline atual;
6. rodar análise e testes;
7. só então abrir uma branch pequena para a próxima fase.

### Comandos iniciais

```bash
git status
git remote -v
git log --oneline -10
flutter analyze
flutter test
rg -n "SnackBar|ScaffoldMessenger" lib test
```

Também revisar o checklist crítico de QA antes de considerar qualquer beta.

---

## 9. QA e beta continuam sendo gate

O projeto segue classificado como **pré-beta interno maduro**.

A base técnica já é forte, mas o beta não deve avançar com bloqueadores como:

- perda de dados;
- duplicação de saldo/ledger/missão/mimo;
- login principal indisponível;
- sync recorrente falhando;
- restore aplicando dados errados;
- wipe local apagando nuvem;
- logout apagando dados locais.

O checklist crítico C01–C32 continua sendo referência obrigatória de validação.

---

## 10. Não fazer agora

- merge automático;
- realtime amplo;
- colaboração multi-dispositivo completa;
- saldo remoto como fonte operacional;
- restaurar streak;
- Rive;
- chat infantil aberto;
- IA tomando decisões;
- IA como requisito para Smart Content;
- premium/assinatura antes de validar beta e custos reais;
- exclusão remota na UI;
- redesign total simultâneo;
- mudanças em sync/ledger/restore sem necessidade real.

---

## 11. Ordem recomendada a partir daqui

1. **Fechar UX + contrato técnico de “Sugerir missões”.**
2. Retomar o projeto Flutter correto no Mac.
3. Rodar baseline (`analyze`, `test`, Git, ausência de SnackBar).
4. Integrar os assets do Smart Content v1.0.
5. Implementar `SmartContentRepository` e `SmartContentService`.
6. Implementar “Sugerir missões” no modo responsável.
7. Integrar templates de rotinas.
8. Testar tudo offline e nos seis idiomas.
9. Não tocar em IA ainda.
10. Continuar QA crítico C01–C32 e device real antes do beta interno.

---

## 12. Prompt sugerido para retomada com Codex/ChatGPT no Mac

> Estou retomando o projeto Flutter atual do Zeni. Leia primeiro `zeni-contexto-geral-aplicativo.md`, `zeni-v2-base-conhecimento-v0.3.md` e o pacote `zeni_smart_content_master_v1_0`.
>
> Preserve integralmente offline-first, auth opcional, saldo local como fonte operacional, ledger, sync, restore, RLS e todas as regras de segurança já definidas.
>
> O Smart Content v1.0 está fechado com 94 missões, 26 rotinas e os locales pt-BR, en, es, fr, de e ja. Os IDs estão congelados.
>
> Não implemente IA. Não altere saldo, ledger, sync, restore ou auth.
>
> Antes de modificar código, faça apenas uma auditoria do projeto atual para localizar onde a integração de `SmartContentRepository`, `SmartContentService`, `MissionSuggestion` e `RoutineTemplate` deve entrar e como reutilizar o fluxo existente de criação de missão. Traga os arquivos impactados e um plano de implementação em fases pequenas.

---

## Resumo de uma linha

**O próximo marco do Zeni não é criar mais conteúdo nem IA: é transformar o Smart Content v1.0 aprovado em uma experiência simples de “Sugerir missões”, preservando integralmente a arquitetura offline-first existente.**
