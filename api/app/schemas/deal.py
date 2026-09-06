from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models.deal import DealStage


class DealBase(BaseModel):
    title: str = Field(min_length=1, max_length=255)
    company_id: int | None = None
    stage: DealStage = DealStage.lead
    value_hkd: Decimal | None = None
    contact_name: str | None = None
    contact_email: EmailStr | None = None
    expected_close: date | None = None
    notes: str | None = None


class DealCreate(DealBase):
    pass


class DealUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=255)
    company_id: int | None = None
    stage: DealStage | None = None
    value_hkd: Decimal | None = None
    contact_name: str | None = None
    contact_email: EmailStr | None = None
    expected_close: date | None = None
    notes: str | None = None


class DealOut(DealBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime
    updated_at: datetime
