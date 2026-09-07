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
      <a href="#main" className="skip-link">
        Skip to main content
      </a>
      <aside className="flex w-60 flex-col border-r border-sps-border bg-white">
        <div className="border-b border-sps-border px-4 py-4">
          <div className="flex items-center gap-3">
            <img
              src="https://static.wixstatic.com/media/ef9572_9049fdb0d6484286a126e71bad334748~mv2.png/v1/fill/w_378,h_194,al_c,q_85,usm_0.66_1.00_0.01,enc_avif,quality_auto/stpatslogo.png"
              alt="St. Patrick's Society Hong Kong"
              className="h-10 w-auto rounded-sm bg-black object-contain"
            />
            <div className="min-w-0">
              <div className="text-[10px] font-semibold uppercase tracking-[0.12em] text-sps-orange">
                St. Patrick&apos;s Society HK
              </div>
              <div className="truncate text-base font-semibold tracking-wide text-sps-green">
                SPS CRM
              </div>
            </div>
          </div>
        </div>
        <nav aria-label="Primary" className="flex flex-1 flex-col gap-1 p-3">
          {nav.map(({ to, label, icon: Icon, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              // React Router sets aria-current="page" on the active link
              className={({ isActive }) =>
                cn(
                  'flex items-center gap-2.5 rounded-md px-3 py-2 text-sm font-medium transition-colors',
                  isActive
                    ? 'bg-sps-green-light text-sps-green'
                    : 'text-sps-muted hover:bg-sps-cream hover:text-sps-ink',
                )
              }
            >
              <Icon className="h-4 w-4 shrink-0" aria-hidden />
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
            <LogOut className="h-3.5 w-3.5" aria-hidden />
            Sign out
          </Button>
        </div>
      </aside>
      <main id="main" tabIndex={-1} className="flex-1 overflow-auto bg-sps-cream outline-none">
        <div className="mx-auto max-w-6xl px-6 py-8">
          <Outlet />
        </div>
      </main>
    </div>
  )
}
