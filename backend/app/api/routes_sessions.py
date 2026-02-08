import logging

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user
from app.models.database import get_session
from app.models.session import Session
from app.models.user import User
from app.schemas.session import (
    SessionCreate,
    SessionDetail,
    SessionListResponse,
    SessionSummary,
    SessionUpdate,
)

log = logging.getLogger("better_mousetrap.routes_sessions")

router = APIRouter(prefix="/sessions", tags=["sessions"])


def _to_summary(s: Session) -> SessionSummary:
    return SessionSummary(
        id=str(s.id),
        title=s.title,
        product_text=s.product_text[:100],
        status=s.status,
        created_at=s.created_at.isoformat(),
        updated_at=s.updated_at.isoformat(),
    )


def _to_detail(s: Session) -> SessionDetail:
    return SessionDetail(
        id=str(s.id),
        product_text=s.product_text,
        product_url=s.product_url,
        variants_json=s.variants_json,
        selected_variant_json=s.selected_variant_json,
        spec_json=s.spec_json,
        patent_hits_json=s.patent_hits_json,
        patent_confidence=s.patent_confidence,
        export_markdown=s.export_markdown,
        export_plain_text=s.export_plain_text,
        patent_draft_json=s.patent_draft_json,
        prototype_json=s.prototype_json,
        status=s.status,
        title=s.title,
        created_at=s.created_at.isoformat(),
        updated_at=s.updated_at.isoformat(),
    )


@router.post("/", response_model=SessionDetail, status_code=status.HTTP_201_CREATED)
async def create_session(
    req: SessionCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    session = Session(
        user_id=user.id,
        product_text=req.product_text,
        product_url=req.product_url,
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return _to_detail(session)


@router.get("/", response_model=SessionListResponse)
async def list_sessions(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    result = await db.execute(
        select(Session)
        .where(Session.user_id == user.id)
        .order_by(Session.updated_at.desc())
        .limit(50)
    )
    sessions = result.scalars().all()
    return SessionListResponse(sessions=[_to_summary(s) for s in sessions])


@router.get("/{session_id}", response_model=SessionDetail)
async def get_session_detail(
    session_id: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    result = await db.execute(
        select(Session).where(Session.id == session_id, Session.user_id == user.id)
    )
    session = result.scalar_one_or_none()
    if session is None:
        raise HTTPException(status_code=404, detail="Session not found")
    return _to_detail(session)


@router.patch("/{session_id}", response_model=SessionDetail)
async def update_session(
    session_id: str,
    req: SessionUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    result = await db.execute(
        select(Session).where(Session.id == session_id, Session.user_id == user.id)
    )
    session = result.scalar_one_or_none()
    if session is None:
        raise HTTPException(status_code=404, detail="Session not found")

    update_data = req.model_dump(exclude_none=True)
    for key, value in update_data.items():
        setattr(session, key, value)

    await db.commit()
    await db.refresh(session)
    return _to_detail(session)


@router.delete("/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_session(
    session_id: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    result = await db.execute(
        select(Session).where(Session.id == session_id, Session.user_id == user.id)
    )
    session = result.scalar_one_or_none()
    if session is None:
        raise HTTPException(status_code=404, detail="Session not found")

    await db.delete(session)
    await db.commit()
