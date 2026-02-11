import ssl as _ssl
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import settings

# Railway's public proxy (caboose.proxy.rlwy.net) uses direct TLS,
# not PostgreSQL's STARTTLS-style SSL negotiation.  We must:
#   1. Create a permissive SSL context (proxy certs fail strict verification)
#   2. Set direct_tls=True so asyncpg wraps the socket in TLS immediately
#      instead of sending an SSLRequest that the proxy doesn't understand
_is_remote = not any(h in settings.database_url for h in ["localhost", "127.0.0.1", "::1"])
_connect_args: dict = {"timeout": 10}
if _is_remote:
    _ctx = _ssl.create_default_context()
    _ctx.check_hostname = False
    _ctx.verify_mode = _ssl.CERT_NONE
    _connect_args["ssl"] = _ctx
    _connect_args["direct_tls"] = True

engine = create_async_engine(
    settings.async_database_url,
    echo=settings.debug,
    connect_args=_connect_args,
    pool_pre_ping=True,
)

async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        yield session
