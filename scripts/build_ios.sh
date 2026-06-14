#!/usr/bin/env bash
set -euo pipefail

if [ ! -f ".env.local" ]; then
  echo "Arquivo .env.local não encontrado. Build de release bloqueado."
  exit 1
fi

set -a
source .env.local
set +a

: "${SUPABASE_URL:?SUPABASE_URL não definido}"
: "${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY não definido}"
: "${GOOGLE_SERVER_CLIENT_ID:?GOOGLE_SERVER_CLIENT_ID não definido}"
: "${GOOGLE_CLIENT_ID:?GOOGLE_CLIENT_ID não definido}"

echo "Configuração carregada para release:"
echo "SUPABASE_URL definido: sim"
echo "SUPABASE_ANON_KEY definido: sim"
echo "GOOGLE_SERVER_CLIENT_ID definido: sim"
echo "GOOGLE_CLIENT_ID definido: sim"
echo "SUPABASE_URL host: $(echo "$SUPABASE_URL" | sed -E 's#https://([^/]+).*#\1#')"

flutter clean
flutter pub get
flutter analyze
flutter test

rg -n "SnackBar|ScaffoldMessenger" lib test && {
  echo "Encontrado SnackBar/ScaffoldMessenger. Build bloqueado."
  exit 1
} || true

flutter build ipa --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=GOOGLE_SERVER_CLIENT_ID="$GOOGLE_SERVER_CLIENT_ID" \
  --dart-define=GOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID"