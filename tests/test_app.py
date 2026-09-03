from fastapi.testclient import TestClient

from app.config import get_settings
from app.database import build_alembic_database_url
from app.main import app

client = TestClient(app)


def test_health() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_status() -> None:
    response = client.get("/api/status")
    assert response.status_code == 200
    assert response.json()["status"] == "running"


def test_home() -> None:
    response = client.get("/")
    assert response.status_code == 200
    assert "AWS PORTFOLIO" in response.text


def test_alembic_url_escapes_percent_signs(monkeypatch) -> None:
    monkeypatch.setenv("DB_PASSWORD", "percent%password")
    get_settings.cache_clear()

    try:
        assert "percent%%25password" in build_alembic_database_url()
    finally:
        get_settings.cache_clear()
