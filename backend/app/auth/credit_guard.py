"""FastAPI dependency that enforces credit availability before paid endpoints."""

from fastapi import Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user
from app.models.database import get_session
from app.models.user import User
from app.services.credits import get_balance


async def require_credits(
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> User:
    """Verify the user has >= 1 credit. Admins bypass."""
    if user.is_admin:
        return user

    balance = await get_balance(session, user.id)
    if balance < 1:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail={
                "error": "insufficient_credits",
                "message": "You need credits to use this feature. Purchase more in the app.",
                "balance": 0,
            },
        )
    return user
