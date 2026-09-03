from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ProjectResponse(BaseModel):
    id: int
    slug: str
    title: str
    summary: str
    repository_url: str
    technologies: list[str]
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
