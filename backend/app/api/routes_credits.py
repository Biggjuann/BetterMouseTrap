"""Credit balance and IAP verification endpoints."""

import logging

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user
from app.models.database import async_session, get_session
from app.models.user import User
from app.services.apple_iap import verify_and_decode_receipt
from app.services.credits import get_balance, grant_purchase_credits

log = logging.getLogger("mousetrap.routes_credits")

router = APIRouter(prefix="/credits", tags=["credits"])

# Product ID -> credit amount mapping
CREDIT_PACKS = {
    "com.mousetrap.credits.10": 10,
    "com.mousetrap.credits.25": 25,
    "com.mousetrap.credits.50": 50,
}


class BalanceResponse(BaseModel):
    balance: int
    is_admin: bool


class VerifyPurchaseRequest(BaseModel):
    transaction_id: str
    product_id: str
    signed_transaction: str  # JWS from StoreKit 2


class VerifyPurchaseResponse(BaseModel):
    success: bool
    credits_granted: int
    new_balance: int


@router.get("/balance", response_model=BalanceResponse)
async def credit_balance(
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    balance = await get_balance(session, user.id)
    return BalanceResponse(balance=balance, is_admin=user.is_admin)


@router.post("/verify-purchase", response_model=VerifyPurchaseResponse)
async def verify_purchase(
    req: VerifyPurchaseRequest,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """Verify Apple IAP receipt and grant credits."""
    credits_amount = CREDIT_PACKS.get(req.product_id)
    if credits_amount is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unknown product: {req.product_id}",
        )

    try:
        verified = await verify_and_decode_receipt(
            signed_transaction=req.signed_transaction,
            expected_product_id=req.product_id,
            expected_bundle_id="com.mousetrap.app",
        )
    except ValueError as e:
        log.warning("IAP verification failed for user %s: %s", user.id, e)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Receipt validation failed: {e}",
        )

    # Grant credits using a fresh DB session to avoid greenlet context
    # issues after the httpx call in verify_and_decode_receipt
    async with async_session() as credit_session:
        try:
            new_balance = await grant_purchase_credits(
                session=credit_session,
                user_id=user.id,
                credits_amount=credits_amount,
                apple_transaction_id=verified["original_transaction_id"],
                product_id=req.product_id,
            )
            await credit_session.commit()
        except Exception as e:
            log.warning("Credit grant failed for user %s: %s: %s", user.id, type(e).__name__, e)
            await credit_session.rollback()
            # IntegrityError = duplicate transaction (already granted) — return current balance
            from sqlalchemy.exc import IntegrityError
            if isinstance(e, IntegrityError):
                balance = await get_balance(credit_session, user.id)
                return VerifyPurchaseResponse(success=True, credits_granted=0, new_balance=balance)
            raise  # surface unexpected errors instead of swallowing them

    log.info("Granted %d credits to user %s (product: %s)", credits_amount, user.id, req.product_id)
    return VerifyPurchaseResponse(
        success=True,
        credits_granted=credits_amount,
        new_balance=new_balance,
    )
