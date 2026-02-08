#!/bin/bash
set -e

# Railway provides the Postgres URL as RAILWAY_SERVICE_POSTGRES_URL
if [ -z "$DATABASE_URL" ] && [ -n "$RAILWAY_SERVICE_POSTGRES_URL" ]; then
    export DATABASE_URL="$RAILWAY_SERVICE_POSTGRES_URL"
    echo "Using RAILWAY_SERVICE_POSTGRES_URL as DATABASE_URL"
fi

echo "DATABASE_URL scheme: ${DATABASE_URL%%://*}"
echo "Running database migrations..."
cd /app && alembic upgrade head

echo "Starting server on port ${PORT:-8000}..."
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}"
