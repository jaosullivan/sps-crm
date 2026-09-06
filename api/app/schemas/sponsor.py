from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models.sponsor import SponsorTier


class SponsorBase(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    company_id: int | None = None
    tier: SponsorTier = SponsorTier.other
    contact_name: str | None = None
    contact_email: EmailStr | None = None
    contact_phone: str | None = None
    amount_hkd: Decimal | None = None
    year: int | None = None
    event_name: str | None = None
    starts_on: date | None = None
    ends_on: date | None = None
    notes: str | None = None


class SponsorCreate(SponsorBase):
    pass


class SponsorUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    company_id: int | None = None
    tier: SponsorTier | None = None
    contact_name: str | None = None
    contact_email: EmailStr | None = None
    contact_phone: str | None = None
    amount_hkd: Decimal | None = None
    year: int | None = None
    event_name: str | None = None
    starts_on: date | None = None
    ends_on: date | None = None
    notes: str | None = None


class SponsorOut(SponsorBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime
    updated_at: datetime
