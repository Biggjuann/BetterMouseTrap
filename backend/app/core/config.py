from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # API keys
    patentsview_api_key: str = ""
    anthropic_api_key: str = ""
    openai_api_key: str = ""

    # LLM
    llm_provider: str = "anthropic"  # "anthropic" or "openai"
    llm_model: str = "claude-sonnet-4-20250514"
    llm_max_tokens: int = 4096

    # PatentsView
    patentsview_base_url: str = "https://search.patentsview.org/api/v1"

    # Database
    database_url: str = "postgresql+asyncpg://localhost:5432/bettermousetrap"

    # Auth
    jwt_secret_key: str = "CHANGE-ME-IN-PRODUCTION"
    jwt_algorithm: str = "HS256"
    jwt_expiration_minutes: int = 1440  # 24 hours

    # Apple Sign-In
    apple_bundle_id: str = "com.mousetrap.app"

    # Admin bootstrap
    admin_email: str = ""
    admin_password: str = ""

    # App
    app_name: str = "MouseTrap"
    debug: bool = False
    allowed_origins: str = "*"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}

    @property
    def async_database_url(self) -> str:
        url = self.database_url
        if url.startswith("postgres://"):
            url = url.replace("postgres://", "postgresql+psycopg://", 1)
        elif url.startswith("postgresql://"):
            url = url.replace("postgresql://", "postgresql+psycopg://", 1)
        elif not url.startswith("postgresql+psycopg://"):
            url = "postgresql+psycopg://" + url.split("://", 1)[-1]
        return url


settings = Settings()
