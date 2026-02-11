import ssl as _ssl
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import settings

# Build connect_args based on the database host:
#   - railway.internal (private networking) → no SSL needed
#   - proxy.rlwy.net  (public proxy)       → SSL with direct TLS
#   - localhost                             → no SSL
_connect_args: dict = {"timeout": 10}
_db_url = settings.database_url.lower()

if ".railway.internal" in _db_url:
    # Private networking — plain TCP, no SSL
    _connect_args["ssl"] = False
elif not any(h in _db_url for h in ["localhost", "127.0.0.1", "::1"]):
    # Public proxy — needs TLS
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
