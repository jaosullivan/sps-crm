from functools import lru_cache

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

WEAK_JWT_SECRETS = frozenset(
    {
        "",
        "change-me",
        "change-me-in-production",
        "changeme",
        "secret",
        "jwt-secret",
        "jwt_secret",
        "dev-secret",
        "development",
    }
)
WEAK_ADMIN_PASSWORDS = frozenset({"", "changeme", "password", "admin", "admin123"})


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "SPS CRM API"
    app_env: str = Field(default="development", validation_alias="APP_ENV")
    api_prefix: str = "/api"
    database_url: str = "postgresql+asyncpg://sps:sps@localhost:5432/sps_crm"
    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24
    cors_origins: str = "http://localhost:5173,http://127.0.0.1:5173"
    admin_email: str = "admin@stpatrickshk.com"
    admin_password: str = "changeme"
    admin_full_name: str = "SPS Admin"

    @property
    def is_production(self) -> bool:
        return self.app_env.strip().lower() in {"production", "prod", "staging"}

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @model_validator(mode="after")
    def enforce_secret_hygiene(self) -> "Settings":
        if not self.is_production:
            return self

        secret = self.jwt_secret.strip()
        if secret.lower() in WEAK_JWT_SECRETS or len(secret) < 32:
            raise ValueError(
                "APP_ENV requires a strong JWT_SECRET "
                "(at least 32 characters, not a placeholder). "
                "Generate one and rotate on every deploy."
            )

        password = self.admin_password.strip()
        if password.lower() in WEAK_ADMIN_PASSWORDS:
            raise ValueError(
                "APP_ENV forbids default/weak ADMIN_PASSWORD "
                "(e.g. changeme). Set a unique password before deploy."
            )
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
