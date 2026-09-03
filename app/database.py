from urllib.parse import quote_plus

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.pool import NullPool

from app.config import get_settings


class Base(DeclarativeBase):
    pass


def build_database_url() -> str:
    settings = get_settings()
    username = quote_plus(settings.db_username)
    password = quote_plus(settings.db_password)
    return (
        f"postgresql+psycopg://{username}:{password}"
        f"@{settings.db_host}:{settings.db_port}/{settings.db_name}"
        f"?sslmode={settings.db_sslmode}&connect_timeout=45"
    )


engine = create_engine(build_database_url(), poolclass=NullPool)
