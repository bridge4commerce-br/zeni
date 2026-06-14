#!/usr/bin/env bash
set -euo pipefail

if [ ! -f ".env.local" ]; then
  echo "Arquivo .env.local não encontrado. Seguindo com execução offline-first sem login/sync."
fi

if [ -f ".env.local" ]; then
  set -a
  source .env.local
  set +a
fi

build_args=()

if [ -n "${SUPABASE_URL:-}" ]; then
  build_args+=(--dart-define=SUPABASE_URL="$SUPABASE_URL")
else
  echo "SUPABASE_URL ausente: execução seguirá sem Supabase/Auth."
fi

if [ -n "${SUPABASE_ANON_KEY:-}" ]; then
  build_args+=(--dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY")
else
  echo "SUPABASE_ANON_KEY ausente: execução seguirá sem Supabase/Auth."
fi

if [ -n "${GOOGLE_SERVER_CLIENT_ID:-}" ]; then
  build_args+=(--dart-define=GOOGLE_SERVER_CLIENT_ID="$GOOGLE_SERVER_CLIENT_ID")
else
  echo "GOOGLE_SERVER_CLIENT_ID ausente: login com Google ficará desabilitado."
fi

if [ -n "${GOOGLE_CLIENT_ID:-}" ]; then
  build_args+=(--dart-define=GOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID")
else
  echo "GOOGLE_CLIENT_ID ausente: login com Google em dispositivos Apple ficará desabilitado."
fi

flutter run "${build_args[@]}"
