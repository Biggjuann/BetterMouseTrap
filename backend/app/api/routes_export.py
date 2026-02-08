from fastapi import APIRouter, Depends

from app.auth.dependencies import get_current_user

from app.schemas.export import ExportRequest, ExportResponse
from app.services.export import build_markdown, build_plain_text

router = APIRouter(prefix="/export", tags=["export"], dependencies=[Depends(get_current_user)])


@router.post("/onepager", response_model=ExportResponse)
async def export_onepager(req: ExportRequest):
    """Generate a one-page concept + prior-art summary."""
    return ExportResponse(
        markdown=build_markdown(req),
        plain_text=build_plain_text(req),
    )
