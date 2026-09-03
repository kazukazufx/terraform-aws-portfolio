import time

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from sqlalchemy import select
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session

from app.config import get_settings
from app.content import ARCHITECTURE, PROFILE, SKILLS
from app.database import engine
from app.models import Project
from app.schemas import ProjectResponse

settings = get_settings()
app = FastAPI(title=settings.app_name, version=settings.app_version)
app.mount("/static", StaticFiles(directory="app/static"), name="static")
templates = Jinja2Templates(directory="app/templates")


@app.get("/", response_class=HTMLResponse)
def home(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(
        request=request,
        name="index.html",
        context={
            "profile": PROFILE,
            "skills": SKILLS,
            "architecture": ARCHITECTURE,
            "environment": settings.app_environment,
            "version": settings.app_version,
        },
    )


@app.get("/health", tags=["operations"])
def health() -> dict[str, str]:
    # DBを確認しないことで、ALBの定期確認がAuroraを起こさないようにする。
    return {"status": "healthy"}


@app.get("/api/status", tags=["operations"])
def status() -> dict[str, str]:
    return {
        "application": settings.app_name,
        "environment": settings.app_environment,
        "version": settings.app_version,
        "status": "running",
    }


def query_projects(statement: object) -> list[Project]:
    # 0 ACUからの復帰には時間がかかるため、接続を一定時間再試行する。
    for attempt in range(5):
        try:
            with Session(engine) as session:
                return list(session.scalars(statement).all())
        except OperationalError:
            if attempt == 4:
                raise
            time.sleep(8)
    return []


@app.get("/api/projects", response_model=list[ProjectResponse], tags=["projects"])
def list_projects() -> list[ProjectResponse]:
    try:
        projects = query_projects(select(Project).order_by(Project.id))
    except OperationalError as error:
        raise HTTPException(
            status_code=503,
            detail="Database is resuming. Please try again shortly.",
        ) from error

    return [
        ProjectResponse(
            id=project.id,
            slug=project.slug,
            title=project.title,
            summary=project.summary,
            repository_url=project.repository_url,
            technologies=[item.strip() for item in project.technologies.split(",")],
            created_at=project.created_at,
        )
        for project in projects
    ]


@app.get(
    "/api/projects/{slug}", response_model=ProjectResponse, tags=["projects"]
)
def get_project(slug: str) -> ProjectResponse:
    try:
        projects = query_projects(select(Project).where(Project.slug == slug))
    except OperationalError as error:
        raise HTTPException(
            status_code=503,
            detail="Database is resuming. Please try again shortly.",
        ) from error

    if not projects:
        raise HTTPException(status_code=404, detail="Project not found")
    project = projects[0]
    return ProjectResponse(
        id=project.id,
        slug=project.slug,
        title=project.title,
        summary=project.summary,
        repository_url=project.repository_url,
        technologies=[item.strip() for item in project.technologies.split(",")],
        created_at=project.created_at,
    )
