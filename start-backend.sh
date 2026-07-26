#!/bin/bash
cd /home/grace/hackaton/activ-education-backend-main
export SERVER_PORT=8080
export JWT_SECRET='NNErf6gZawDYmFuEa4hGA/yZKGQ9HZMZvwNvjwqajjdF5vfDg92r7KqmtXfDWdq5qwxrrxJ/OtBFcp5R+ayCdw=='

# ── Connexion Supabase PostgreSQL (pooler transaction mode) ──
export DB_HOST=db.ejvxcimlceataldtntxg.supabase.co
export DB_PORT=6543
export DB_NAME=postgres
export DB_USER=postgres
export DB_PASSWORD=OriaContactHeubLab

# ── Supabase REST API ──
export SUPABASE_URL=https://ejvxcimlceataldtntxg.supabase.co
export SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqdnhjaW1sY2VhdGFsZHRudHhnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NTAxMjU5NiwiZXhwIjoyMTAwNTg4NTk2fQ.80PcUEpAraWCaOISE1Qeo2L5GAJdxmCNUZDJGhykRc0

exec java -jar target/activEducation-0.0.1-SNAPSHOT.jar > /tmp/backend-final.log 2>&1
