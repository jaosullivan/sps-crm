import type {
  Company,
  CompanyCreate,
  CompanyUpdate,
  DashboardStats,
  Deal,
  DealCreate,
  DealStage,
  DealUpdate,
  LoginRequest,
  LoginResponse,
  Member,
  MemberCreate,
  MemberUpdate,
  Sponsor,
  SponsorCreate,
  SponsorUpdate,
  User,
} from '@/types'

const TOKEN_KEY = 'sps_crm_token'
const USER_KEY = 'sps_crm_user'

const API_BASE =
  (import.meta.env.VITE_API_BASE_URL as string | undefined)?.replace(/\/$/, '') ||
  'http://localhost:8000'

export class ApiError extends Error {
  status: number
  body: unknown

  constructor(message: string, status: number, body?: unknown) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.body = body
  }
}

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY)
}

export function setAuth(token: string, user: User): void {
  localStorage.setItem(TOKEN_KEY, token)
  localStorage.setItem(USER_KEY, JSON.stringify(user))
}

export function clearAuth(): void {
  localStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem(USER_KEY)
}

export function getStoredUser(): User | null {
  const raw = localStorage.getItem(USER_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw) as User
  } catch {
    return null
  }
}

export function isAuthenticated(): boolean {
  return Boolean(getToken())
}

async function request<T>(
  path: string,
  options: RequestInit = {},
  auth = true,
): Promise<T> {
  const headers = new Headers(options.headers)
  if (!headers.has('Content-Type') && options.body) {
    headers.set('Content-Type', 'application/json')
  }
  if (auth) {
    const token = getToken()
    if (token) headers.set('Authorization', `Bearer ${token}`)
  }

  const res = await fetch(`${API_BASE}${path}`, { ...options, headers })

  if (res.status === 204) {
    return undefined as T
  }

  const text = await res.text()
  let data: unknown = null
  if (text) {
    try {
      data = JSON.parse(text)
    } catch {
      data = text
    }
  }

  if (!res.ok) {
    if (res.status === 401) {
      clearAuth()
    }
    const msg =
      typeof data === 'object' &&
      data !== null &&
      'detail' in data &&
      typeof (data as { detail: unknown }).detail === 'string'
        ? (data as { detail: string }).detail
        : `Request failed (${res.status})`
    throw new ApiError(msg, res.status, data)
  }

  return data as T
}

function qs(params?: Record<string, string | undefined>): string {
  if (!params) return ''
  const sp = new URLSearchParams()
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== '') sp.set(k, v)
  })
  const s = sp.toString()
  return s ? `?${s}` : ''
}

export const api = {
  login(body: LoginRequest) {
    return request<LoginResponse>(
      '/api/auth/login',
      { method: 'POST', body: JSON.stringify(body) },
      false,
    )
  },

  me() {
    return request<User>('/api/auth/me')
  },

  dashboardStats() {
    return request<DashboardStats>('/api/dashboard/stats')
  },

  // Members
  listMembers(q?: string) {
    return request<Member[]>(`/api/members${qs({ q })}`)
  },
  getMember(id: number) {
    return request<Member>(`/api/members/${id}`)
  },
  createMember(body: MemberCreate) {
    return request<Member>('/api/members', {
      method: 'POST',
      body: JSON.stringify(body),
    })
  },
  updateMember(id: number, body: MemberUpdate) {
    return request<Member>(`/api/members/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    })
  },
  deleteMember(id: number) {
    return request<void>(`/api/members/${id}`, { method: 'DELETE' })
  },

  // Sponsors
  listSponsors(q?: string) {
    return request<Sponsor[]>(`/api/sponsors${qs({ q })}`)
  },
  getSponsor(id: number) {
    return request<Sponsor>(`/api/sponsors/${id}`)
  },
  createSponsor(body: SponsorCreate) {
    return request<Sponsor>('/api/sponsors', {
      method: 'POST',
      body: JSON.stringify(body),
    })
  },
  updateSponsor(id: number, body: SponsorUpdate) {
    return request<Sponsor>(`/api/sponsors/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    })
  },
  deleteSponsor(id: number) {
    return request<void>(`/api/sponsors/${id}`, { method: 'DELETE' })
  },

  // Companies
  listCompanies(q?: string) {
    return request<Company[]>(`/api/companies${qs({ q })}`)
  },
  getCompany(id: number) {
    return request<Company>(`/api/companies/${id}`)
  },
  createCompany(body: CompanyCreate) {
    return request<Company>('/api/companies', {
      method: 'POST',
      body: JSON.stringify(body),
    })
  },
  updateCompany(id: number, body: CompanyUpdate) {
    return request<Company>(`/api/companies/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    })
  },
  deleteCompany(id: number) {
    return request<void>(`/api/companies/${id}`, { method: 'DELETE' })
  },

  // Deals
  listDeals(params?: { q?: string; stage?: DealStage }) {
    return request<Deal[]>(
      `/api/deals${qs({ q: params?.q, stage: params?.stage })}`,
    )
  },
  getDeal(id: number) {
    return request<Deal>(`/api/deals/${id}`)
  },
  createDeal(body: DealCreate) {
    return request<Deal>('/api/deals', {
      method: 'POST',
      body: JSON.stringify(body),
    })
  },
  updateDeal(id: number, body: DealUpdate) {
    return request<Deal>(`/api/deals/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    })
  },
  deleteDeal(id: number) {
    return request<void>(`/api/deals/${id}`, { method: 'DELETE' })
  },
}

export { API_BASE }
