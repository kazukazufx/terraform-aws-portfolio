from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "AWS Portfolio"
    app_environment: str = "dev"
    app_version: str = "local"

    db_host: str = "localhost"
    db_port: int = 5432
    db_name: str = "portfolio"
    db_username: str = "portfolio_admin"
    db_password: str = "portfolio_local"
    db_sslmode: str = "prefer"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    return Settings()
