from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import settings

# Railway private networking does NOT support SSL — the Postgres server
# rejects SSLRequest immediately (ConnectionResetError).  We must pass
# ssl=False so asyncpg skips the SSL handshake entirely for remote DBs.
_is_remote = not any(h in settings.database_url for h in ["localhost", "127.0.0.1", "::1"])
_connect_args = {"ssl": False} if _is_remote else {}

engine = create_async_engine(
    settings.async_database_url,
    echo=settings.debug,
    connect_args=_connect_args,
)

async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        yield session
