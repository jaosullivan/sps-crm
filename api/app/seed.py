"""Seed admin user and sample CRM rows. Idempotent."""

import asyncio

from sqlalchemy import select

from app.core.config import get_settings
from app.core.security import hash_password
from app.database import Base, SessionLocal, engine
from app.models import (
    Company,
    Deal,
    DealStage,
    Member,
    MembershipStatus,
    Sponsor,
    SponsorTier,
    User,
)


async def seed() -> None:
    settings = get_settings()
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with SessionLocal() as db:
        admin_email = settings.admin_email.lower()
        admin = (
            await db.execute(select(User).where(User.email == admin_email))
        ).scalar_one_or_none()
        if admin is None:
            db.add(
                User(
                    email=admin_email,
                    full_name=settings.admin_full_name,
                    hashed_password=hash_password(settings.admin_password),
                    is_admin=True,
                    is_active=True,
                )
            )
            print(f"Seeded admin {admin_email}")
        else:
            print(f"Admin already exists: {admin_email}")

        has_member = (
            await db.execute(select(Member.id).limit(1))
        ).scalar_one_or_none()
        if has_member is None:
            db.add_all(
                [
                    Member(
                        first_name="Aoife",
                        last_name="Murphy",
                        email="aoife.murphy@example.com",
                        phone="+852 5550 1001",
                        company_name="Independent",
                        status=MembershipStatus.active,
                        green_card_number="GC-1001",
                    ),
                    Member(
                        first_name="Liam",
                        last_name="Byrne",
                        email="liam.byrne@example.com",
                        status=MembershipStatus.active,
                        green_card_number="GC-1002",
                    ),
                ]
            )
            print("Seeded sample members")

        company = (
            await db.execute(select(Company).where(Company.name == "Avolon"))
        ).scalar_one_or_none()
        if company is None:
            company = Company(
                name="Avolon",
                website="https://www.avolon.aero",
                industry="Aviation",
            )
            db.add(company)
            await db.flush()
            db.add(
                Sponsor(
                    name="Avolon — Ball Gold",
                    company_id=company.id,
                    tier=SponsorTier.gold,
                    contact_email="partnerships@example.com",
                    year=2026,
                    event_name="St Patrick's Gala Ball",
                    amount_hkd=100000,
                )
            )
            db.add(
                Deal(
                    title="2027 Ball Gold sponsorship",
                    company_id=company.id,
                    stage=DealStage.proposal,
                    value_hkd=120000,
                    contact_name="Partnerships",
                )
            )
            print("Seeded sample company / sponsor / deal")

        await db.commit()


if __name__ == "__main__":
    asyncio.run(seed())
