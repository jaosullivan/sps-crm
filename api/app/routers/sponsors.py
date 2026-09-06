from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_user
from app.models import Sponsor, User
from app.schemas.sponsor import SponsorCreate, SponsorOut, SponsorUpdate

router = APIRouter(prefix="/sponsors", tags=["sponsors"])


@router.get("", response_model=list[SponsorOut])
async def list_sponsors(
    q: str | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> list[Sponsor]:
    stmt = select(Sponsor).order_by(Sponsor.name)
    if q:
        stmt = stmt.where(Sponsor.name.ilike(f"%{q}%"))
    result = await db.execute(stmt)
    return list(result.scalars().all())


@router.post("", response_model=SponsorOut, status_code=status.HTTP_201_CREATED)
async def create_sponsor(
    body: SponsorCreate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Sponsor:
    sponsor = Sponsor(**body.model_dump())
    db.add(sponsor)
    await db.commit()
    await db.refresh(sponsor)
    return sponsor


@router.get("/{sponsor_id}", response_model=SponsorOut)
async def get_sponsor(
    sponsor_id: int,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Sponsor:
    sponsor = await db.get(Sponsor, sponsor_id)
    if not sponsor:
        raise HTTPException(status_code=404, detail="Sponsor not found")
    return sponsor


@router.patch("/{sponsor_id}", response_model=SponsorOut)
async def update_sponsor(
    sponsor_id: int,
    body: SponsorUpdate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Sponsor:
    sponsor = await db.get(Sponsor, sponsor_id)
    if not sponsor:
        raise HTTPException(status_code=404, detail="Sponsor not found")
    for key, value in body.model_dump(exclude_unset=True).items():
        setattr(sponsor, key, value)
    await db.commit()
    await db.refresh(sponsor)
    return sponsor


@router.delete("/{sponsor_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_sponsor(
    sponsor_id: int,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> None:
    sponsor = await db.get(Sponsor, sponsor_id)
    if not sponsor:
        raise HTTPException(status_code=404, detail="Sponsor not found")
    await db.delete(sponsor)
    await db.commit()
