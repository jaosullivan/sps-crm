from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models.member import MembershipStatus


class MemberBase(BaseModel):
    first_name: str = Field(min_length=1, max_length=120)
    last_name: str = Field(min_length=1, max_length=120)
    email: EmailStr
    phone: str | None = None
    company_name: str | None = None
    status: MembershipStatus = MembershipStatus.active
    green_card_number: str | None = None
    joined_on: date | None = None
    notes: str | None = None


class MemberCreate(MemberBase):
    pass


class MemberUpdate(BaseModel):
    first_name: str | None = Field(default=None, min_length=1, max_length=120)
    last_name: str | None = Field(default=None, min_length=1, max_length=120)
    email: EmailStr | None = None
    phone: str | None = None
    company_name: str | None = None
    status: MembershipStatus | None = None
    green_card_number: str | None = None
    joined_on: date | None = None
    notes: str | None = None


class MemberOut(MemberBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime
    updated_at: datetime
