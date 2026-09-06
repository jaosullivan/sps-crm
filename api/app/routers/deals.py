from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_user
from app.models import Deal, DealStage, User
from app.schemas.deal import DealCreate, DealOut, DealUpdate

router = APIRouter(prefix="/deals", tags=["deals"])


@router.get("", response_model=list[DealOut])
async def list_deals(
    stage: DealStage | None = Query(default=None),
    q: str | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> list[Deal]:
    stmt = select(Deal).order_by(Deal.updated_at.desc())
    if stage:
        stmt = stmt.where(Deal.stage == stage)
    if q:
        stmt = stmt.where(Deal.title.ilike(f"%{q}%"))
    result = await db.execute(stmt)
    return list(result.scalars().all())


@router.post("", response_model=DealOut, status_code=status.HTTP_201_CREATED)
async def create_deal(
    body: DealCreate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Deal:
    deal = Deal(**body.model_dump())
    db.add(deal)
    await db.commit()
    await db.refresh(deal)
    return deal


@router.get("/{deal_id}", response_model=DealOut)
async def get_deal(
    deal_id: int,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Deal:
    deal = await db.get(Deal, deal_id)
    if not deal:
        raise HTTPException(status_code=404, detail="Deal not found")
    return deal


@router.patch("/{deal_id}", response_model=DealOut)
async def update_deal(
    deal_id: int,
    body: DealUpdate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Deal:
    deal = await db.get(Deal, deal_id)
    if not deal:
        raise HTTPException(status_code=404, detail="Deal not found")
    for key, value in body.model_dump(exclude_unset=True).items():
        setattr(deal, key, value)
    await db.commit()
    await db.refresh(deal)
    return deal


@router.delete("/{deal_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_deal(
    deal_id: int,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> None:
    deal = await db.get(Deal, deal_id)
    if not deal:
        raise HTTPException(status_code=404, detail="Deal not found")
    await db.delete(deal)
    await db.commit()
