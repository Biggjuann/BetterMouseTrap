# ── Stage 1: Build Flutter web ────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-build
WORKDIR /build

COPY flutter_app/ ./flutter_app/
WORKDIR /build/flutter_app
RUN flutter pub get && \
    flutter build web --release --dart-define=API_BASE_URL=""

# ── Stage 2: Python backend + static assets ──────────────────────
FROM python:3.12-slim
WORKDIR /app

# System deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq5 && \
    rm -rf /var/lib/apt/lists/*

# Python deps
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Backend source
COPY backend/ .

# Flutter web build → /app/static/
COPY --from=flutter-build /build/flutter_app/build/web/ /app/static/

# Startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENV PORT=8000
EXPOSE 8000

CMD ["/app/start.sh"]
