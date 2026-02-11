#!/bin/bash

# Prefer Railway private networking (bypasses proxy, no SSL needed).
# Fall back to public DATABASE_URL if private isn't available.
if [ -n "$DATABASE_PRIVATE_URL" ]; then
    export DATABASE_URL="$DATABASE_PRIVATE_URL"
    echo "Using DATABASE_PRIVATE_URL (private networking)"
elif [ -z "$DATABASE_URL" ] && [ -n "$RAILWAY_SERVICE_POSTGRES_URL" ]; then
    export DATABASE_URL="$RAILWAY_SERVICE_POSTGRES_URL"
    echo "Using RAILWAY_SERVICE_POSTGRES_URL"
else
    echo "Using DATABASE_URL"
fi

# ── Diagnostics: understand DB connectivity before trying migrations ──
echo "=== DATABASE CONNECTION DIAGNOSTICS ==="
echo "DATABASE_URL set: $([ -n "$DATABASE_URL" ] && echo 'YES' || echo 'NO')"
echo "RAILWAY_SERVICE_POSTGRES_URL set: $([ -n "$RAILWAY_SERVICE_POSTGRES_URL" ] && echo 'YES' || echo 'NO')"

python3 -c "
import os, urllib.parse, socket

url = os.environ.get('DATABASE_URL', '')
if not url:
    print('ERROR: DATABASE_URL is empty!')
else:
    # Parse without exposing password
    parsed = urllib.parse.urlparse(url)
    print(f'DB scheme:   {parsed.scheme}')
    print(f'DB host:     {parsed.hostname}')
    print(f'DB port:     {parsed.port or 5432}')
    print(f'DB name:     {parsed.path}')
    print(f'DB user:     {parsed.username}')
    print(f'DB query:    {parsed.query}')

    host = parsed.hostname
    port = parsed.port or 5432

    # DNS resolution
    try:
        addrs = socket.getaddrinfo(host, port, socket.AF_UNSPEC, socket.SOCK_STREAM)
        print(f'DNS resolve:  OK ({len(addrs)} addresses)')
        for addr in addrs[:3]:
            print(f'  -> {addr[4][0]}:{addr[4][1]}')
    except Exception as e:
        print(f'DNS resolve:  FAILED - {e}')

    # Raw TCP connection test
    try:
        sock = socket.create_connection((host, port), timeout=5)
        sock.close()
        print(f'TCP connect:  OK')
    except Exception as e:
        print(f'TCP connect:  FAILED - {e}')
"
echo "=== END DIAGNOSTICS ==="

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
