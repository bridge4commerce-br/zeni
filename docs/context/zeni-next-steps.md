# Zeni — Próximos Passos Recomendados

## 1. Executar o checklist crítico `C01–C32`

Motivo:

- É o gate mais real para beta interno.
- O projeto já tem base técnica suficiente; agora precisa validação integrada.

O que não fazer nesta etapa:

- não abrir refatorações
- não adicionar features
- não “melhorar” visual por iniciativa própria

## 2. Corrigir apenas falhas críticas encontradas no QA

Motivo:

- Mantém o escopo controlado e protege a estabilidade do beta.
- Evita regressão em áreas sensíveis como sync, saldo, ledger, auth e restore.

O que não fazer nesta etapa:

- não aproveitar para mexer em arquitetura
- não redesenhar fluxos estáveis
- não alterar contratos Supabase sem necessidade absoluta

## 3. Validar em device real os fluxos principais

Motivo:

- Google/Apple login, biometria, comportamento visual e estabilidade longa precisam de validação fora do ambiente de teste.
- Sync e restauração com dados remotos reais podem revelar edge cases não cobertos localmente.

O que não fazer nesta etapa:

- não confiar só em simulador
- não considerar beta pronto sem checagem em aparelho real

## 4. Fechar revisão final de UX, legal e suporte

Motivo:

- O produto já expõe textos sobre privacidade, dados locais/nuvem, termos e suporte.
- Antes do beta, a comunicação precisa estar clara e coerente com o comportamento real do app.

O que não fazer nesta etapa:

- não prometer exclusão remota ativa se ela estiver fora da fase atual
- não deixar textos ambíguos sobre offline, logout, wipe local e nuvem

## 5. Preparar distribuição interna controlada

Motivo:

- Depois do QA e dos ajustes bloqueadores, o próximo passo natural é TestFlight/Play interno.
- Isso permite feedback real sem expandir escopo técnico.

O que não fazer nesta etapa:

- não incluir features novas antes da primeira rodada de beta
- não liberar sem critérios mínimos de estabilidade e recuperação de dados
