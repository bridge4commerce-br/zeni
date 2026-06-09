# QA Manual — Beta Interno 01

## Instruções

- Status permitido: `Pendente`, `Passou`, `Falhou`.
- Registrar observações sempre que houver falha.
- Falhas críticas de dados, saldo, auth, sync ou restauração bloqueiam beta.

## Testes críticos antes do beta

| ID | Cenário | Pré-condição | Passos | Resultado esperado | Status | Observações |
|---|---|---|---|---|---|---|
| C01 | Instalação limpa abre onboarding local | App limpo, sem login | Abrir app pela 1ª vez | Onboarding aparece; login não é obrigatório | Pendente | |
| C02 | Criar família local | App no onboarding | Seguir “Começar nova família” | Família/criança inicial criada sem erro | Pendente | |
| C03 | Criar missão local | Família criada | Entrar como responsável, criar missão | Missão salva e aparece nas listas corretas | Pendente | |
| C04 | Criar mimo local | Família criada | Criar mimo | Mimo salvo e visível para a criança correta | Pendente | |
| C05 | Fluxo criança básico | Família com missão/mimo | Entrar no modo criança | Tela carrega, perfil correto, sem acesso indevido a Ajustes | Pendente | |
| C06 | Fluxo responsável básico | Família criada | Entrar como responsável | Shell do responsável abre sem erro | Pendente | |
| C07 | Uso offline continua funcional | Dados locais já criados | Desligar internet, criar/editar dados, concluir missão, pedir mimo | App continua funcional; dados locais persistem | Pendente | |
| C08 | Saldo e histórico locais offline | Internet desligada | Concluir missão automática e pedir mimo | Saldo/histórico local atualizam corretamente | Pendente | |
| C09 | Reentrada online estável | Ação offline concluída | Religar internet e navegar no app | App permanece estável, sem perda local | Pendente | |
| C10 | Login por e-mail | Supabase configurado | Abrir conta, entrar com e-mail/senha válidos | Sessão autenticada; conta conectada aparece em Ajustes | Pendente | |
| C11 | Erro de autenticação controlado | Conta conhecida | Entrar com senha errada | Mensagem controlada; app não trava | Pendente | |
| C12 | Logout preserva dados locais | Sessão autenticada, dados locais existentes | Tocar em “Sair da conta” | Sessão é removida; crianças/missões/mimos locais continuam | Pendente | |
| C13 | Login Google | Device compatível | Entrar com Google | Sessão autenticada; UI atualiza corretamente | Pendente | |
| C14 | Login Apple | iPhone/iPad real, se aplicável | Entrar com Apple | Sessão autenticada; UI atualiza corretamente | Pendente | |
| C15 | Sync geral inicial | Sessão autenticada, família remota preparada | Rodar sincronização | Família/crianças/missões/mimos/logs/pedidos/ledger sincronizam sem erro | Pendente | |
| C16 | Sync repetido sem duplicação | Sync inicial concluído | Rodar sincronização novamente | Nenhuma duplicação remota/local aparente | Pendente | |
| C17 | Diagnóstico da nuvem | Conta conectada | Abrir Ajustes/Sincronização | Diagnóstico carrega sem erro técnico indevido | Pendente | |
| C18 | Restauração em aparelho limpo | Conta com dados remotos principais | Limpar app, fazer login, tocar em restaurar dados principais | Família, crianças, missões e mimos restaurados | Pendente | |
| C19 | Restauração principal não traz saldo/histórico | Após C18 | Conferir perfis e histórico | Saldo/histórico/streak não vêm nessa etapa | Pendente | |
| C20 | Restauração histórica e saldo | Dados principais já restaurados, sem atividade local | Tocar em “Restaurar histórico e saldo” | Logs, pedidos, ledger e saldo local restaurados com sucesso | Pendente | |
| C21 | Streak não é restaurado | Após C20 | Verificar perfis | Sequência/streak permanece fora da restauração | Pendente | |
| C22 | Bloqueio de restauração histórica com atividade local | Aparelho com atividade local | Abrir Ajustes/Sincronização | Ação bloqueada com explicação clara | Pendente | |
| C23 | Wipe local com confirmação errada | Dados locais existentes | Abrir “Apagar dados deste aparelho”, digitar texto incorreto | Nada é apagado | Pendente | |
| C24 | Wipe local com APAGAR | Dados locais existentes | Repetir fluxo e digitar `APAGAR` | Dados locais são apagados; app volta ao onboarding | Pendente | |
| C25 | Wipe local não apaga nuvem | Após C24 | Fazer login novamente e testar restauração/sync | Dados remotos continuam disponíveis | Pendente | |
| C26 | Exclusão remota continua indisponível | Conta conectada | Abrir “Conta e dados” | “Excluir conta e dados da nuvem” aparece só como informativo/indisponível | Pendente | |
| C27 | PIN do responsável | App com modo responsável | Configurar PIN e sair/entrar do modo responsável | Bloqueio por PIN funciona | Pendente | |
| C28 | Biometria do responsável | Device com biometria | Habilitar biometria e testar acesso | Biometria funciona ou cai em fallback previsto | Pendente | |
| C29 | Missão automática no modo criança | Missão automática existente | Concluir missão | Estrela/animação/saldo funcionam corretamente | Pendente | |
| C30 | Missão com aprovação | Missão com aprovação existente | Concluir no modo criança, aprovar no responsável | Não credita antes; credita uma vez após aprovação | Pendente | |
| C31 | Pedido de mimo | Mimo disponível | Solicitar mimo no modo criança | Pedido fica pendente e segue fluxo esperado | Pendente | |
| C32 | Regressão visual crítica | App em uso normal | Percorrer onboarding, criança, responsável, Ajustes | Sem textos quebrados, overflow, travamentos ou UI técnica demais | Pendente | |

## Testes recomendados

| ID | Cenário | Pré-condição | Passos | Resultado esperado | Status | Observações |
|---|---|---|---|---|---|---|
| R01 | Telas pequenas | Device pequeno/simulador | Navegar pelas telas principais | Conteúdo continua acessível e legível | Pendente | |
| R02 | Acessibilidade/preferências | App com dados | Alterar fonte, escala, vibração, TTS, etc. | Preferências persistem e não quebram layout | Pendente | |
| R03 | Tema claro/escuro | Se disponível | Alternar tema | App permanece consistente visualmente | Pendente | |
| R04 | Edição de nome da família remota | Conta conectada | Editar nome em Ajustes | Atualiza corretamente sem erro | Pendente | |
| R05 | Logout e login repetidos | Conta válida | Sair e entrar mais de uma vez | Estado local permanece íntegro | Pendente | |
| R06 | Sync após uso offline | Ações locais feitas offline | Religar internet e sincronizar | Sync conclui sem duplicação aparente | Pendente | |
| R07 | Restore principal sem dados remotos | Conta sem dados remotos principais | Fazer login em aparelho limpo | Mensagem controlada informa ausência de dados | Pendente | |
| R08 | Legal e suporte | App aberto | Abrir Política, Termos, Suporte, Dados locais e nuvem | Conteúdo abre corretamente em folhas internas | Pendente | |
| R09 | Navegação criança/responsável repetida | App com dados | Alternar entre modos várias vezes | Sem inconsistência visual ou estado perdido | Pendente | |
| R10 | Estabilidade longa | Sessão de 15-20 min | Usar fluxos principais continuamente | Sem crash, travamento ou perda de estado | Pendente | |

## Critérios de liberação

### Liberado

- Todos os testes `C01–C32` passaram.
- Nenhum bug crítico de perda de dados, duplicação de estrelas, autenticação bloqueada ou sync/restauração inconsistente.
- No máximo bugs cosméticos menores nos testes recomendados.

### Precisa ajuste

- 1 a 3 falhas não bloqueadoras fora de perda de dados/segurança.
- Workaround claro e risco baixo para beta interno controlado.

### Bloqueado

- Qualquer falha em perda de dados locais/remotos.
- Duplicação de saldo/ledger/recompensa/missão.
- Login principal indisponível.
- Sync geral falhando de forma recorrente.
- Restore principal ou histórico aplicando dados errados.
- Wipe local apagando nuvem ou logout apagando dados locais.

## Ordem sugerida de execução

1. `C01–C06`
2. `C07–C12`
3. `C15–C22`
4. `C23–C31`
5. `C32`
6. `R01–R10`

## Modelo de registro de falha

- ID:
- Data:
- Ambiente:
- O que aconteceu:
- O que era esperado:
- Evidência:
- Risco:
- Bloqueia beta?
- Próxima ação:
