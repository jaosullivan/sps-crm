/** Types aligned with api/API_CONTRACT.md v0.1 */

export type MemberStatus = 'active' | 'lapsed' | 'complimentary'
export type SponsorTier = 'gold' | 'silver' | 'bronze' | 'in_kind' | 'other'
export type DealStage = 'lead' | 'contacted' | 'proposal' | 'won' | 'lost'

export interface User {
  id: number
  email: string
  full_name?: string | null
  is_active?: boolean
}

export interface LoginRequest {
  email: string
  password: string
}

export interface LoginResponse {
  access_token: string
  token_type: 'bearer' | string
  user: User
}

export interface Member {
  id: number
  first_name: string
  last_name: string
  email: string
  phone?: string | null
  company_name?: string | null
  status: MemberStatus
  green_card_number?: string | null
  joined_on?: string | null
  notes?: string | null
  created_at?: string
  updated_at?: string
}

export type MemberCreate = Omit<Member, 'id' | 'created_at' | 'updated_at'>
export type MemberUpdate = Partial<MemberCreate>

export interface Sponsor {
  id: number
  name: string
  company_id?: number | null
  tier: SponsorTier
  contact_name?: string | null
  contact_email?: string | null
  contact_phone?: string | null
  amount_hkd?: number | string | null
  year?: number | null
  event_name?: string | null
  starts_on?: string | null
  ends_on?: string | null
  notes?: string | null
  created_at?: string
  updated_at?: string
}

export type SponsorCreate = Omit<Sponsor, 'id' | 'created_at' | 'updated_at'>
export type SponsorUpdate = Partial<SponsorCreate>

export interface Company {
  id: number
  name: string
  website?: string | null
  industry?: string | null
  notes?: string | null
  created_at?: string
  updated_at?: string
}

export type CompanyCreate = Omit<Company, 'id' | 'created_at' | 'updated_at'>
export type CompanyUpdate = Partial<CompanyCreate>

export interface Deal {
  id: number
  title: string
  company_id?: number | null
  stage: DealStage
  value_hkd?: number | string | null
  contact_name?: string | null
  contact_email?: string | null
  expected_close?: string | null
  notes?: string | null
  created_at?: string
  updated_at?: string
}

export type DealCreate = Omit<Deal, 'id' | 'created_at' | 'updated_at'>
export type DealUpdate = Partial<DealCreate>

export interface DashboardStats {
  members_total: number
  members_active: number
  sponsors_total: number
  companies_total: number
  deals_total: number
  deals_by_stage: Record<DealStage, number>
  pipeline_value_hkd: string | number
  won_value_hkd: string | number
}

export const DEAL_STAGES: DealStage[] = [
  'lead',
  'contacted',
  'proposal',
  'won',
  'lost',
]

export const MEMBER_STATUSES: MemberStatus[] = [
  'active',
  'lapsed',
  'complimentary',
]

export const SPONSOR_TIERS: SponsorTier[] = [
  'gold',
  'silver',
  'bronze',
  'in_kind',
  'other',
]
