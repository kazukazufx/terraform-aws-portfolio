"""Create and seed projects table."""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "20260903_01"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    projects = op.create_table(
        "projects",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("slug", sa.String(length=100), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.Column("repository_url", sa.String(length=500), nullable=False),
        sa.Column("technologies", sa.String(length=500), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index("ix_projects_slug", "projects", ["slug"], unique=True)
    op.bulk_insert(
        projects,
        [
            {
                "slug": "terraform-aws-portfolio",
                "title": "Terraform AWS Portfolio",
                "summary": (
                    "ECS/FargateとAurora Serverless v2で構築した"
                    "ポートフォリオ基盤"
                ),
                "repository_url": "https://github.com/kazukazufx/terraform-aws-portfolio",
                "technologies": "Terraform,AWS,ECS,Aurora,FastAPI,GitHub Actions",
            }
        ],
    )


def downgrade() -> None:
    op.drop_index("ix_projects_slug", table_name="projects")
    op.drop_table("projects")
