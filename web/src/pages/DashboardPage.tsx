import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  Award,
  Building2,
  Handshake,
  Users,
} from 'lucide-react'
import { api, ApiError } from '@/lib/api'
import { formatHkd } from '@/lib/utils'
import type { DashboardStats, DealStage } from '@/types'
import { DEAL_STAGES } from '@/types'
import { PageHeader } from '@/components/PageHeader'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { EmptyState } from '@/components/EmptyState'

export function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const data = await api.dashboardStats()
        if (!cancelled) setStats(data)
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof ApiError ? err.message : 'Failed to load stats')
        }
      } finally {
        if (!cancelled) setLoading(false)
      }
    })()
    return () => {
      cancelled = true
    }
  }, [])

  const cards = stats
    ? [
        {
          label: 'Members',
          value: stats.members_total,
          sub: `${stats.members_active} active`,
          to: '/members',
          icon: Users,
        },
        {
          label: 'Sponsors',
          value: stats.sponsors_total,
          sub: 'All tiers',
          to: '/sponsors',
          icon: Award,
        },
        {
          label: 'Companies',
          value: stats.companies_total,
          sub: 'Organisations',
          to: '/companies',
          icon: Building2,
        },
        {
          label: 'Deals',
          value: stats.deals_total,
          sub: `Pipeline ${formatHkd(stats.pipeline_value_hkd)}`,
          to: '/deals',
          icon: Handshake,
        },
      ]
    : []

  return (
    <div>
      <PageHeader
        title="Dashboard"
        description="Overview of St. Patrick's Society HK CRM."
      />
      {loading ? <p className="text-sm text-sps-muted">Loading stats...</p> : null}
      {error ? (
        <p className="rounded-md bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p>
      ) : null}
      {stats ? (
        <>
          {stats.members_total === 0 &&
          stats.sponsors_total === 0 &&
          stats.companies_total === 0 &&
          stats.deals_total === 0 ? (
            <div className="mb-6 rounded-lg border border-sps-green-pale bg-white">
              <EmptyState
                title="Welcome to SPS CRM"
                description="Your workspace is ready. Add members, sponsors, companies, or deals to see activity here."
              />
            </div>
          ) : null}
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {cards.map(({ label, value, sub, to, icon: Icon }) => (
              <Link key={label} to={to}>
                <Card className="transition-shadow hover:shadow-md">
                  <CardHeader className="flex flex-row items-center justify-between pb-2">
                    <CardTitle className="text-sm font-medium text-sps-muted">
                      {label}
                    </CardTitle>
                    <Icon className="h-4 w-4 text-sps-green" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-3xl font-semibold text-sps-ink">{value}</div>
                    <p className="mt-1 text-xs text-sps-muted">{sub}</p>
                  </CardContent>
                </Card>
              </Link>
            ))}
          </div>

          <div className="mt-6 grid gap-4 lg:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>Deals by stage</CardTitle>
              </CardHeader>
              <CardContent>
                <ul className="space-y-2">
                  {DEAL_STAGES.map((stage: DealStage) => (
                    <li
                      key={stage}
                      className="flex items-center justify-between rounded-md bg-sps-cream px-3 py-2 text-sm"
                    >
                      <span className="capitalize text-sps-ink">{stage}</span>
                      <span className="font-semibold text-sps-green">
                        {stats.deals_by_stage?.[stage] ?? 0}
                      </span>
                    </li>
                  ))}
                </ul>
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle>Pipeline value</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <div className="text-xs uppercase tracking-wide text-sps-muted">
                    Open pipeline
                  </div>
                  <div className="text-2xl font-semibold text-sps-ink">
                    {formatHkd(stats.pipeline_value_hkd)}
                  </div>
                </div>
                <div>
                  <div className="text-xs uppercase tracking-wide text-sps-muted">
                    Won value
                  </div>
                  <div className="text-2xl font-semibold text-sps-green">
                    {formatHkd(stats.won_value_hkd)}
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </>
      ) : null}
    </div>
  )
}
