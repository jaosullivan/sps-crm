from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_user
from app.models import Member, User
from app.schemas.member import MemberCreate, MemberOut, MemberUpdate

router = APIRouter(prefix="/members", tags=["members"])


@router.get("", response_model=list[MemberOut])
async def list_members(
    q: str | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> list[Member]:
    stmt = select(Member).order_by(Member.last_name, Member.first_name)
    if q:
        like = f"%{q}%"
        stmt = stmt.where(
            (Member.first_name.ilike(like))
            | (Member.last_name.ilike(like))
            | (Member.email.ilike(like))
        )
    result = await db.execute(stmt)
    return list(result.scalars().all())


@router.post("", response_model=MemberOut, status_code=status.HTTP_201_CREATED)
async def create_member(
    body: MemberCreate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Member:
    existing = await db.execute(select(Member).where(Member.email == body.email.lower()))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Member email already exists")
    member = Member(**body.model_dump())
    member.email = body.email.lower()
    db.add(member)
    await db.commit()
    await db.refresh(member)
    return member


@router.get("/{member_id}", response_model=MemberOut)
async def get_member(
    member_id: int,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Member:
    member = await db.get(Member, member_id)
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")
    return member


@router.patch("/{member_id}", response_model=MemberOut)
async def update_member(
    member_id: int,
    body: MemberUpdate,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> Member:
    member = await db.get(Member, member_id)
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")
    data = body.model_dump(exclude_unset=True)
    if "email" in data and data["email"]:
        data["email"] = data["email"].lower()
    for key, value in data.items():
        setattr(member, key, value)
    await db.commit()
    await db.refresh(member)
    return member


@router.delete("/{member_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_member(
    member_id: int,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
) -> None:
    member = await db.get(Member, member_id)
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")
    await db.delete(member)
    await db.commit()
