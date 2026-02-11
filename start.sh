#!/bin/bash

# Railway provides the Postgres URL as RAILWAY_SERVICE_POSTGRES_URL
if [ -z "$DATABASE_URL" ] && [ -n "$RAILWAY_SERVICE_POSTGRES_URL" ]; then
    export DATABASE_URL="$RAILWAY_SERVICE_POSTGRES_URL"
fi

# Run migrations with retry logic (DB may take a moment to become reachable)
MAX_RETRIES=5
RETRY_DELAY=3
cd /app
for i in $(seq 1 $MAX_RETRIES); do
    echo "Running database migrations (attempt $i/$MAX_RETRIES)..."
    if alembic upgrade head; then
        echo "Migrations completed successfully."
        break
    fi
    if [ "$i" -eq "$MAX_RETRIES" ]; then
        echo "WARNING: Migrations failed after $MAX_RETRIES attempts. Starting server anyway."
    else
        echo "Migration failed, retrying in ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
        RETRY_DELAY=$((RETRY_DELAY * 2))
    fi
done

echo "Starting server on port ${PORT:-8000}..."
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}"
