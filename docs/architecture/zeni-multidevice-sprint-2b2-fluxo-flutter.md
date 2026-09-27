# Sprint 2B.2 — resolução canônica no Flutter

## Fluxo auditado antes da alteração

Após autenticação por e-mail, Google ou Apple, o cliente consultava diretamente
`family_members` com join em `families`. Quando não obtinha exatamente uma
família, o login verificava `FamilyIdentity.isEmptySafe` e, para uma base local
vazia, chamava automaticamente `ensure_user_family()`. A mesma abstração de
resumo remoto era consumida por sync, bootstrap, restore e controllers de
domínio. O `FamilyIdentityGuard` já bloqueava mismatch e bases locais inseguras,
mas a resolução e a criação remotas ainda não tinham resultados canônicos
tipados no cliente.

## Fluxo adotado na Sprint 2B.2

Todo login autenticado chama `resolve_current_family()` por meio do account
repository. Seus estados são convertidos para contratos Dart tipados, sem
comparações de strings na UI:

- `found`: usa a família canônica retornada e não cria outra;
- `notFound`: somente uma base aprovada por `FamilyIdentity.isEmptySafe` chama
  explicitamente `create_initial_family()`;
- `ambiguous` ou `inconsistent`: mantém a sessão, preserva os dados locais e
  bloqueia a preparação cloud com mensagem explícita;
- falha técnica ou resposta inválida: não é confundida com estado de domínio.

`create_initial_family()` aceita `created` e `alreadyExists` como resolução
bem-sucedida. `ambiguous` e `inconsistent` continuam bloqueantes. O login
revalida a sessão após cada espera assíncrona e compartilha uma única preparação
em andamento por usuário, evitando duas criações pelo mesmo controller.

Uma base local com dados não vinculados nunca chama a criação remota e nunca é
adotada implicitamente. O `FamilyIdentityGuard` permanece como autoridade para
as regras de compatibilidade e proteção das operações de domínio.

## Compatibilidade temporária

`ensure_user_family()` e os wrappers Dart legados permanecem disponíveis para
compatibilidade, mas o fluxo normal de login e o carregamento canônico da
família não dependem mais deles. Sua remoção, junto com a revisão das ACLs e das
write policies antigas, fica fora desta sprint.
