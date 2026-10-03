#!/bin/bash
# Secrets via environnement uniquement — aucun secret en clair ici.
# Requis : JWT_SECRET, DB_PASSWORD, SUPABASE_SERVICE_ROLE_KEY
# (fournis par l'environnement ou le .env gitignoré).
set -u
: "${JWT_SECRET:?JWT_SECRET manquant}"
: "${DB_PASSWORD:?DB_PASSWORD manquant}"
: "${SUPABASE_SERVICE_ROLE_KEY:?SUPABASE_SERVICE_ROLE_KEY manquante}"
cd /home/grace/hackaton/oria-backend-main
export SERVER_PORT=8080

# ── Connexion Supabase PostgreSQL (pooler transaction mode) ──
export DB_HOST="${DB_HOST:-db.ejvxcimlceataldtntxg.supabase.co}"
export DB_PORT="${DB_PORT:-6543}"
export DB_NAME="${DB_NAME:-postgres}"
export DB_USER="${DB_USER:-postgres}"

# ── Supabase REST API ──
export SUPABASE_URL="${SUPABASE_URL:-https://ejvxcimlceataldtntxg.supabase.co}"

exec java -jar target/activEducation-0.0.1-SNAPSHOT.jar > /tmp/backend-final.log 2>&1
