from fastapi.testclient import TestClient

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
