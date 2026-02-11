import logging
import os
import sys
import traceback

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from sqlalchemy import text

from app.api.routes_build_this import router as build_router
from app.api.routes_export import router as export_router
from app.api.routes_ideas import router as ideas_router
from app.api.routes_patents import router as patents_router
from app.api.routes_sessions import router as sessions_router
from app.auth.bootstrap import ensure_admin_user
from app.auth.routes import router as auth_router
from app.core.config import settings
from app.models.database import async_session

# ── Logging ──────────────────────────────────────────────────────
if not settings.debug:
    logging.basicConfig(
        level=logging.INFO,
        format='{"time":"%(asctime)s","level":"%(levelname)s","logger":"%(name)s","message":"%(message)s"}',
        stream=sys.stdout,
    )
else:
    logging.basicConfig(level=logging.DEBUG)

log = logging.getLogger("mousetrap")

app = FastAPI(title=settings.app_name, debug=settings.debug)

# ── Rate limiting ───────────────────────────────────────────────────
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ── CORS ────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ─────────────────────────────────────────────────────────
app.include_router(auth_router)
app.include_router(ideas_router)
app.include_router(patents_router)
app.include_router(export_router)
app.include_router(sessions_router)
app.include_router(build_router)


# ── Global exception handler — surface real errors ────────────────
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    tb = traceback.format_exception(type(exc), exc, exc.__traceback__)
    log.error("Unhandled %s on %s %s:\n%s", type(exc).__name__, request.method, request.url.path, "".join(tb))
    return JSONResponse(
        status_code=500,
        content={"detail": f"{type(exc).__name__}: {exc}"},
    )


# ── Health ──────────────────────────────────────────────────────────
@app.get("/health")
async def health():
    db_ok = False
    db_err = None
    try:
        async with async_session() as session:
            await session.execute(text("SELECT 1"))
            db_ok = True
    except Exception as e:
        db_err = f"{type(e).__name__}: {e}"
        log.exception("Health check: database unreachable")

    has_llm = bool(
        (settings.llm_provider == "anthropic" and settings.anthropic_api_key)
        or (settings.llm_provider == "openai" and settings.openai_api_key)
    )

    overall = "ok" if db_ok else "degraded"
    return {
        "status": overall,
        "database": "connected" if db_ok else "unreachable",
        "database_error": db_err,
        "llm_provider": settings.llm_provider,
        "llm_key_set": has_llm,
        "db_url_prefix": settings.database_url[:30] + "..." if len(settings.database_url) > 30 else settings.database_url,
    }


# ── Startup ─────────────────────────────────────────────────────────
@app.on_event("startup")
async def on_startup():
    if not settings.debug and settings.jwt_secret_key == "CHANGE-ME-IN-PRODUCTION":
        raise RuntimeError("JWT_SECRET_KEY must be changed in production!")
    try:
        await ensure_admin_user()
    except Exception:
        log.warning("Could not ensure admin user (database may be unreachable). Will retry on first request.")


# ── Static file serving (for production Docker build) ───────────────
static_dir = os.path.join(os.path.dirname(__file__), "..", "static")
if os.path.isdir(static_dir):
    # Serve Flutter web assets
    assets_dir = os.path.join(static_dir, "assets")
    if os.path.isdir(assets_dir):
        app.mount("/assets", StaticFiles(directory=assets_dir), name="assets")

    icons_dir = os.path.join(static_dir, "icons")
    if os.path.isdir(icons_dir):
        app.mount("/icons", StaticFiles(directory=icons_dir), name="icons")

    @app.get("/{full_path:path}")
    async def serve_spa(full_path: str):
        """Catch-all: serve Flutter web SPA."""
        file_path = os.path.join(static_dir, full_path)
        if os.path.isfile(file_path):
            return FileResponse(file_path)
        return FileResponse(
            os.path.join(static_dir, "index.html"),
            headers={"Cache-Control": "no-cache"},
        )
