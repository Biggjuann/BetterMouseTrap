#!/bin/bash
set -e

echo "=== Debug: Database env vars ==="
echo "DATABASE_URL set: ${DATABASE_URL:+(yes)}"
echo "DATABASE_URL first 30 chars: ${DATABASE_URL:0:30}"
env | grep -i -E "database|postgres|pghost|pgport|pguser|pgpass|pgdatabase" | sed 's/=.*/=***/' || true
echo "=== End debug ==="
echo "Running database migrations..."
cd /app && alembic upgrade head

echo "Starting server on port ${PORT:-8000}..."
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}"
