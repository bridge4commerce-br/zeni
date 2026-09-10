# Zeni Design System V1

**Status:** referência oficial para novas interfaces V2.

## 1. Objetivo

Formalizar a foundation visual já existente como fonte da verdade para novas interfaces V2. Este documento não cria um segundo design system, não migra telas legadas e não altera regras de produto.

## 2. Princípios

1. Reutilizar antes de criar.
2. Preferir papéis semânticos a valores nominais ou arbitrários.
3. Usar composição, espaço e divisores antes de adicionar superfícies.
4. Manter uma única foundation para Parent e Child.
5. Tratar acessibilidade, responsividade e tema como requisitos de base.
6. Separar mudanças visuais de regras de negócio.
7. Fazer mudanças pequenas, testáveis e revisáveis.

## 3. Foundation oficial

A foundation oficial está em `lib/core/theme`, `lib/core/layout` e `lib/core/widgets`. Ela inclui cores, tipografia, espaçamento, raio, sombras, animação, expressão visual, breakpoints, larguras, grids, frames, modais, surfaces, ações, entradas, feedback, navegação e marca.

Arquivos de referência: `zeni_colors.dart`, `zeni_typography.dart`, `zeni_spacing.dart`, `zeni_radius.dart`, `zeni_shadows.dart`, `zeni_visual_mode.dart` e `zeni_responsive.dart`.

## 4. Tokens

| Categoria | Fonte da verdade | Regra |
| --- | --- | --- |
| Cores | `ZeniSemanticColors` e `ZeniColors` | Novos fluxos V2 priorizam `context.zeniColors`. |
| Tipografia | `ZeniTypography` | Usar papéis retornados por `ZeniTypography.of(context)`. |
| Espaçamento | `ZeniSpacing` | Usar escala e aliases existentes. |
| Radius | `ZeniRadius` e `ZeniVisualMode` | A expressão Parent/Kids passa pela foundation. |
| Sombras | `ZeniShadows` | Elevação é excepcional e comunica hierarquia. |
| Responsividade | `ZeniResponsive` | Não criar breakpoints locais. |

Não duplicar escalas nem criar tokens a partir de uma ocorrência isolada. Cores ilustrativas, assets e elementos decorativos específicos não viram tokens automaticamente.

## 5. Superfícies

`ZeniSurface` é a primitive oficial para novos fluxos V2. Usar superfície somente quando comunicar agrupamento, destaque, interação ou separação estrutural indispensável. Espaço, título e divisor são preferíveis a um card decorativo.

| Papel | Quando usar |
| --- | --- |
| `plain` | Conteúdo no canvas, seções com espaço e listas sem moldura. |
| `grouped` | Conjunto relacionado de linhas ou controles com uma fronteira. |
| `highlight` | Próxima ação, resumo importante, observação ou decisão. |
| `interactive` | Área inteira clicável que precisa comunicar affordance. |

Evitar uma superfície por item: em listas homogêneas, preferir uma superfície agrupada e divisores. Conteúdo puramente textual não precisa de superfície.

## 6. Botões

`ZeniButton` é o componente oficial para ações V2. Usar `primary` para a ação principal, `secondary` para alternativa importante, `tertiary` para ação auxiliar e `destructive` para confirmação de ação destrutiva. Não criar estilos de botão específicos para uma única tela.

Usar `ZeniIconActionButton` para ação contextual por ícone, com tooltip, semântica e alvo de toque adequado. Estado disabled mantém legibilidade; loading preserva largura e rótulo perceptível. Parent usa ação primária de 48 px; Child usa 56 px; ambos mantêm alvo mínimo de 48 px.

## 7. Tipografia

Usar `ZeniTypography.of(context)` e os papéis `display`, `pageTitle`, `sectionTitle`, `cardTitle`, `body`, `bodyEmphasis`, `metadata`, `button` e `chip`. Evitar `TextStyle` local com `fontSize`, `fontWeight` ou `letterSpacing` arbitrários.

`w900` não é padrão de expressão infantil. Fredoka embarcada suporta pesos de 300 a 700; OpenDyslexic deve permanecer nos pesos disponíveis 400 e 700. Toda composição deve funcionar com Fredoka, OpenDyslexic e text scaling, sem reduzir acessibilidade ou omitir conteúdo essencial.

## 8. Espaçamento

A escala oficial é `4 / 8 / 12 / 16 / 24 / 32 / 48 / 64`. Priorizar `spaceInlineTight`, `spaceInline`, `spaceControl`, `spaceCard`, `spaceGroup`, `spaceSection`, `spaceHero` e `spaceCanvas`.

Valores como `13`, `15`, `18`, `19` ou `22` exigem justificativa técnica explícita. Ajustes ópticos pequenos ficam restritos a componente-base ou exceção ilustrativa documentada.

## 9. Radius

Usar `ZeniRadius` e `ZeniVisualMode` em novas telas V2. Não declarar `BorderRadius.circular(...)` diretamente, exceto em ilustração ou exceção tecnicamente justificada. Parent é mais compacto e sóbrio; Child é mais expressivo e acolhedor, sem escalas independentes.

## 10. Cores

Em fluxos V2, priorizar `context.zeniColors` para ação, texto, canvas, superfície, borda, estrela e foco. `ZeniColors` continua compatível com código existente, mas não é a primeira opção para código novo.

Os status `success`, `warning`, `error` e `info` ainda não possuem papéis semânticos completos para todos os containers e contrastes. Quando a foundation não cobrir uma necessidade, apontar a lacuna antes de improvisar uma cor de produto. Não substituir automaticamente cores ilustrativas.

## 11. Parent x Child

Parent e Child compartilham tokens, primitives, responsividade e requisitos de acessibilidade. Não existem dois Design Systems independentes. A diferenciação ocorre por `ZeniVisualMode`, densidade, raio, padding, composição, ilustração e motion.

- Parent: claro, organizado, confiável e orientado a decisão.
- Child: amigável, expressivo, recompensador e legível.

O modo visual não altera dados, regras, navegação, permissões ou acessibilidade.

## 12. Componentes de domínio

Missões, recompensas, rotinas, mimos e aprovações permanecem em suas features quando carregam semântica de produto. Promover para `core/widgets` somente padrão genérico comprovado, sem dados, texto ou callbacks de domínio.

## 13. Legacy policy

`ZeniCard`, `ZeniPrimaryButton` e `ZeniSecondaryButton` são componentes de compatibilidade para telas existentes. Não removê-los nem migrar consumidores nesta etapa. Novos fluxos V2 não devem introduzi-los; devem usar `ZeniSurface` e `ZeniButton`. Migrações futuras ocorrem por fluxo aprovado, preservando comportamento offline, regras, acessibilidade e testes.

## 14. Guardrails de implementação

1. Procurar primeiro primitive, componente ou pattern existente.
2. Procurar primeiro token existente.
3. Não introduzir valor visual arbitrário sem justificativa explícita.
4. Preferir composição antes de criar um componente novo.
5. Não usar componentes legacy em código novo.
6. Preservar diferenças Parent/Child pela foundation.
7. Não alterar regras de negócio durante mudança visual.
8. Executar testes relevantes após mudanças.
9. Preferir alterações pequenas e revisáveis.
10. Declarar uma lacuna do Design System em vez de improvisar silenciosamente.

## 15. Processo de migração

1. Escolher fluxo isolado e aprovado como piloto.
2. Mapear componentes legacy e estilos diretos do escopo.
3. Substituir apenas decisões visuais pela foundation oficial.
4. Preservar callbacks, dados, estados, navegação e comportamento offline.
5. Cobrir compact, tablet, texto ampliado e OpenDyslexic quando aplicável.
6. Validar visualmente e executar análise, testes e verificações de diff.
7. Registrar patterns somente após evidência em dois ou três fluxos V2.

## 16. Candidatos a patterns futuros

Os itens abaixo são candidatos, não componentes oficiais. Não implementá-los sem repetição comprovada:

- `ZeniGroupedList`
- `ZeniSectionHeader`
- `ZeniEmptyNotice`

## 17. Checklist para novas telas

- [ ] Usa tokens existentes.
- [ ] Usa `ZeniTypography`.
- [ ] Usa `ZeniSurface` quando uma superfície é necessária.
- [ ] Usa `ZeniButton` para ações.
- [ ] Não adiciona `ZeniCard`.
- [ ] Não adiciona botões legacy.
- [ ] Não introduz radius arbitrário.
- [ ] Não introduz spacing arbitrário.
- [ ] Não introduz cores de produto fora da semântica.
- [ ] Respeita `ZeniVisualMode`.
- [ ] Funciona com text scaling.
- [ ] Funciona nos breakpoints suportados.
- [ ] Mantém regras de negócio inalteradas.
- [ ] Testes relevantes passam.
