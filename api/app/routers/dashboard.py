from decimal import Decimal

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_user
from app.models import Company, Deal, DealStage, Member, MembershipStatus, Sponsor, User
from app.schemas.dashboard import DashboardStats

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("/stats", response_model=DashboardStats)
async def stats(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> DashboardStats:
    members_total = (await db.execute(select(func.count()).select_from(Member))).scalar_one()
    members_active = (
        await db.execute(
            select(func.count())
            .select_from(Member)
            .where(Member.status == MembershipStatus.active)
        )
    ).scalar_one()
    sponsors_total = (
        await db.execute(select(func.count()).select_from(Sponsor))
    ).scalar_one()
    companies_total = (
        await db.execute(select(func.count()).select_from(Company))
    ).scalar_one()
    deals_total = (await db.execute(select(func.count()).select_from(Deal))).scalar_one()

    stage_rows = (
        await db.execute(select(Deal.stage, func.count()).group_by(Deal.stage))
    ).all()
    deals_by_stage = {stage.value: 0 for stage in DealStage}
    for stage, count in stage_rows:
        deals_by_stage[stage.value] = count

    open_stages = (DealStage.lead, DealStage.contacted, DealStage.proposal)
    pipeline_value = (
        await db.execute(
            select(func.coalesce(func.sum(Deal.value_hkd), 0)).where(
                Deal.stage.in_(open_stages)
            )
        )
    ).scalar_one()
    won_value = (
        await db.execute(
            select(func.coalesce(func.sum(Deal.value_hkd), 0)).where(
                Deal.stage == DealStage.won
            )
        )
    ).scalar_one()

    return DashboardStats(
        members_total=members_total,
        members_active=members_active,
        sponsors_total=sponsors_total,
        companies_total=companies_total,
        deals_total=deals_total,
        deals_by_stage=deals_by_stage,
        pipeline_value_hkd=Decimal(pipeline_value),
        won_value_hkd=Decimal(won_value),
    )
