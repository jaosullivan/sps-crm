from decimal import Decimal

from pydantic import BaseModel


class DashboardStats(BaseModel):
    members_total: int
    members_active: int
    sponsors_total: int
    companies_total: int
    deals_total: int
    deals_by_stage: dict[str, int]
    pipeline_value_hkd: Decimal
    won_value_hkd: Decimal
