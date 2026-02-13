"""Credit balance management — append-only ledger approach."""

import logging
import uuid

from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.credit import CreditTransaction

log = logging.getLogger("mousetrap.credits")

SIGNUP_BONUS = 5


async def get_balance(session: AsyncSession, user_id: uuid.UUID) -> int:
    """Get current credit balance from the latest transaction."""
    result = await session.execute(
        select(CreditTransaction.balance_after)
        .where(CreditTransaction.user_id == user_id)
        .order_by(desc(CreditTransaction.created_at))
        .limit(1)
    )
    row = result.scalar_one_or_none()
    return row if row is not None else 0


async def grant_signup_bonus(session: AsyncSession, user_id: uuid.UUID) -> int:
    """Grant initial free credits. Idempotent — skips if already granted."""
    existing = await session.execute(
        select(CreditTransaction.id)
        .where(
            CreditTransaction.user_id == user_id,
            CreditTransaction.transaction_type == "signup_bonus",
        )
        .limit(1)
    )
    if existing.scalar_one_or_none() is not None:
        return await get_balance(session, user_id)

    txn = CreditTransaction(
        user_id=user_id,
        amount=SIGNUP_BONUS,
        balance_after=SIGNUP_BONUS,
        transaction_type="signup_bonus",
        description=f"Welcome bonus: {SIGNUP_BONUS} free credits",
    )
    session.add(txn)
    await session.flush()
    return SIGNUP_BONUS


async def deduct_credit(
    session: AsyncSession,
    user_id: uuid.UUID,
    transaction_type: str,
    reference_id: str | None = None,
    description: str | None = None,
) -> int:
    """Deduct 1 credit. Returns new balance. Raises ValueError if insufficient."""
    current = await get_balance(session, user_id)
    if current < 1:
        raise ValueError("Insufficient credits")

    new_balance = current - 1
    txn = CreditTransaction(
        user_id=user_id,
        amount=-1,
        balance_after=new_balance,
        transaction_type=transaction_type,
        reference_id=reference_id,
        description=description,
    )
    session.add(txn)
    await session.flush()
    return new_balance


async def grant_purchase_credits(
    session: AsyncSession,
    user_id: uuid.UUID,
    credits_amount: int,
    apple_transaction_id: str,
    product_id: str,
) -> int:
    """Grant credits from IAP. apple_transaction_id unique constraint prevents double-granting."""
    current = await get_balance(session, user_id)
    new_balance = current + credits_amount

    txn = CreditTransaction(
        user_id=user_id,
        amount=credits_amount,
        balance_after=new_balance,
        transaction_type="purchase",
        apple_transaction_id=apple_transaction_id,
        description=f"Purchased {credits_amount} credits ({product_id})",
    )
    session.add(txn)
    await session.flush()
    return new_balance
