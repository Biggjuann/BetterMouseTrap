"""Bootstrap the first admin user on startup if configured."""

import logging

from sqlalchemy import select

from app.auth.security import hash_password
from app.core.config import settings
from app.models.database import async_session
from app.models.user import User

log = logging.getLogger("better_mousetrap.bootstrap")


async def ensure_admin_user() -> None:
    if not settings.admin_email or not settings.admin_password:
        log.info("ADMIN_EMAIL/ADMIN_PASSWORD not set — skipping admin bootstrap")
        return

    async with async_session() as session:
        result = await session.execute(select(User).where(User.email == settings.admin_email))
        existing = result.scalar_one_or_none()

        if existing is not None:
            log.info("Admin user %s already exists", settings.admin_email)
            return

        admin = User(
            email=settings.admin_email,
            password_hash=hash_password(settings.admin_password),
            is_active=True,
            is_admin=True,
        )
        session.add(admin)
        await session.commit()
        log.info("Created admin user: %s", settings.admin_email)
