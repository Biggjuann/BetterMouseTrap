"""Auth endpoints: login, register, invite, me, apple sign-in."""

import logging
import secrets
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.apple import verify_apple_identity_token
from app.auth.dependencies import get_current_user
from app.auth.security import create_access_token, hash_password, verify_password
from app.models.database import get_session
from app.models.user import InviteCode, User
from app.services.credits import get_balance, grant_signup_bonus

log = logging.getLogger("mousetrap.auth")

router = APIRouter(prefix="/auth", tags=["auth"])


# ── Schemas ─────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    email: str = Field(max_length=254)
    password: str = Field(min_length=8, max_length=128)
    invite_code: str | None = Field(default=None, max_length=64)


class AppleAuthRequest(BaseModel):
    identity_token: str
    email: str | None = None
    full_name: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: str
    email: str
    is_admin: bool
    credit_balance: int

    class Config:
        from_attributes = True


class InviteResponse(BaseModel):
    code: str


# ── Endpoints ───────────────────────────────────────────────────────

@router.post("/login", response_model=TokenResponse)
async def login(
    form: OAuth2PasswordRequestForm = Depends(),
    session: AsyncSession = Depends(get_session),
):
    result = await session.execute(select(User).where(User.email == form.username))
    user = result.scalar_one_or_none()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Apple-only users have no password
    if not user.password_hash:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This account uses Sign in with Apple. Please use that option instead.",
        )

    if not verify_password(form.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account disabled")

    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(access_token=token)


@router.post("/register", response_model=TokenResponse)
async def register(
    req: RegisterRequest,
    session: AsyncSession = Depends(get_session),
):
    invited_by = None

    # If invite code provided, validate it
    if req.invite_code:
        result = await session.execute(
            select(InviteCode).where(InviteCode.code == req.invite_code, InviteCode.used_by.is_(None))
        )
        invite = result.scalar_one_or_none()

        if invite is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or used invite code")

        if invite.expires_at and invite.expires_at < datetime.now(timezone.utc):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invite code has expired")

        invited_by = invite.created_by

    # Check if email already taken
    existing = await session.execute(select(User).where(User.email == req.email))
    if existing.scalar_one_or_none() is not None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")

    # Create user
    user = User(
        email=req.email,
        password_hash=hash_password(req.password),
        invited_by=invited_by,
    )
    session.add(user)
    await session.flush()

    # Grant signup bonus credits
    await grant_signup_bonus(session, user.id)

    # Mark invite as used (if one was provided)
    if req.invite_code and invited_by is not None:
        result = await session.execute(
            select(InviteCode).where(InviteCode.code == req.invite_code)
        )
        invite = result.scalar_one()
        invite.used_by = user.id
        invite.used_at = datetime.now(timezone.utc)

    await session.commit()

    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(access_token=token)


@router.post("/apple", response_model=TokenResponse)
async def apple_auth(
    req: AppleAuthRequest,
    session: AsyncSession = Depends(get_session),
):
    """Sign in (or register) with Apple identity token."""
    try:
        claims = await verify_apple_identity_token(req.identity_token)
    except ValueError as e:
        log.warning("Apple token verification failed: %s", e)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Apple authentication failed: {e}",
        )

    apple_user_id = claims["sub"]

    # Check if user already exists with this Apple ID
    result = await session.execute(
        select(User).where(User.apple_user_id == apple_user_id)
    )
    user = result.scalar_one_or_none()

    if user is not None:
        if not user.is_active:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account disabled")
        token = create_access_token({"sub": str(user.id)})
        return TokenResponse(access_token=token)

    # New user — create account
    email = req.email or claims.get("email") or f"{apple_user_id}@privaterelay.appleid.com"

    # Check if an email-based account already exists — link Apple ID to it
    result = await session.execute(select(User).where(User.email == email))
    existing = result.scalar_one_or_none()

    if existing is not None:
        existing.apple_user_id = apple_user_id
        await session.commit()
        token = create_access_token({"sub": str(existing.id)})
        return TokenResponse(access_token=token)

    # Brand new user
    user = User(
        email=email,
        apple_user_id=apple_user_id,
        password_hash=None,
    )
    session.add(user)
    await session.flush()

    # Grant signup bonus credits
    await grant_signup_bonus(session, user.id)

    await session.commit()

    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(access_token=token)


@router.get("/me", response_model=UserResponse)
async def me(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    balance = await get_balance(session, current_user.id)
    return UserResponse(
        id=str(current_user.id),
        email=current_user.email,
        is_admin=current_user.is_admin,
        credit_balance=balance,
    )


@router.post("/invite", response_model=InviteResponse)
async def create_invite(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    if not current_user.is_admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin access required")

    code = secrets.token_urlsafe(16)
    invite = InviteCode(code=code, created_by=current_user.id)
    session.add(invite)
    await session.commit()

    return InviteResponse(code=code)
