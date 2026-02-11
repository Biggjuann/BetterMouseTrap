import ssl
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import settings

# Railway Postgres requires SSL but uses certs that fail strict verification.
# Create a permissive SSL context so asyncpg connects without cert validation.
_ssl_context = ssl.create_default_context()
_ssl_context.check_hostname = False
_ssl_context.verify_mode = ssl.CERT_NONE

_is_remote = not any(h in settings.database_url for h in ["localhost", "127.0.0.1", "::1"])
_connect_args = {"ssl": _ssl_context} if _is_remote else {}

engine = create_async_engine(
    settings.async_database_url,
    echo=settings.debug,
    connect_args=_connect_args,
)

async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        yield session
