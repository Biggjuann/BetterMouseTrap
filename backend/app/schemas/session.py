from pydantic import BaseModel, Field


class SessionCreate(BaseModel):
    product_text: str = Field(max_length=5000)
    product_url: str | None = Field(default=None, max_length=2000)


class SessionUpdate(BaseModel):
    variants_json: list[dict] | None = None
    selected_variant_json: dict | None = None
    spec_json: dict | None = None
    patent_hits_json: list[dict] | None = None
    patent_confidence: str | None = None
    export_markdown: str | None = None
    export_plain_text: str | None = None
    patent_draft_json: dict | None = None
    prototype_json: dict | None = None
    status: str | None = None
    title: str | None = None


class SessionSummary(BaseModel):
    id: str
    title: str | None
    product_text: str
    status: str
    created_at: str
    updated_at: str

    class Config:
        from_attributes = True


class SessionDetail(BaseModel):
    id: str
    product_text: str
    product_url: str | None
    variants_json: list[dict] | None
    selected_variant_json: dict | None
    spec_json: dict | None
    patent_hits_json: list[dict] | None
    patent_confidence: str | None
    export_markdown: str | None
    export_plain_text: str | None
    patent_draft_json: dict | None
    prototype_json: dict | None
    status: str
    title: str | None
    created_at: str
    updated_at: str

    class Config:
        from_attributes = True


class SessionListResponse(BaseModel):
    sessions: list[SessionSummary]
