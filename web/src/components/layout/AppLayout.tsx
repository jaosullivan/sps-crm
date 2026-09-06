import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import {
  Building2,
  Handshake,
  LayoutDashboard,
  LogOut,
  Users,
  Award,
} from 'lucide-react'
import { useAuth } from '@/context/AuthContext'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'

const nav = [
  { to: '/', label: 'Dashboard', icon: LayoutDashboard, end: true },
  { to: '/members', label: 'Members', icon: Users },
  { to: '/sponsors', label: 'Sponsors', icon: Award },
  { to: '/companies', label: 'Companies', icon: Building2 },
  { to: '/deals', label: 'Deals', icon: Handshake },
]

export function AppLayout() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login', { replace: true })
  }

  return (
    <div className="flex min-h-screen">
      <aside className="flex w-60 flex-col border-r border-sps-border bg-white">
        <div className="border-b border-sps-border px-5 py-5">
          <div className="text-xs font-semibold uppercase tracking-wider text-sps-gold">
            St. Patrick&apos;s Society
          </div>
          <div className="mt-0.5 text-lg font-semibold text-sps-green">SPS CRM</div>
          <p className="mt-1 text-xs text-sps-muted">Hong Kong</p>
        </div>
        <nav className="flex flex-1 flex-col gap-1 p-3">
          {nav.map(({ to, label, icon: Icon, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                cn(
                  'flex items-center gap-2.5 rounded-md px-3 py-2 text-sm font-medium transition-colors',
                  isActive
                    ? 'bg-sps-green-light text-sps-green'
                    : 'text-sps-muted hover:bg-sps-cream hover:text-sps-ink',
                )
              }
            >
              <Icon className="h-4 w-4 shrink-0" />
              {label}
            </NavLink>
          ))}
        </nav>
        <div className="border-t border-sps-border p-4">
          <div className="mb-2 truncate text-sm font-medium text-sps-ink">
            {user?.full_name || user?.email}
          </div>
          <div className="mb-3 truncate text-xs text-sps-muted">{user?.email}</div>
          <Button variant="outline" size="sm" className="w-full" onClick={handleLogout}>
            <LogOut className="h-3.5 w-3.5" />
            Sign out
          </Button>
        </div>
      </aside>
      <main className="flex-1 overflow-auto">
        <div className="mx-auto max-w-6xl px-6 py-8">
          <Outlet />
        </div>
      </main>
    </div>
  )
}
