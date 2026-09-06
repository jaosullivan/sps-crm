import { FormEvent, useState } from 'react'
import { Navigate, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '@/context/AuthContext'
import { ApiError } from '@/lib/api'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

export function LoginPage() {
  const { user, loading, login } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const from = (location.state as { from?: { pathname?: string } } | null)?.from?.pathname || '/'

  const [email, setEmail] = useState('admin@stpatrickshk.com')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  if (!loading && user) {
    return <Navigate to={from} replace />
  }

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)
    setSubmitting(true)
    try {
      await login({ email, password })
      navigate(from, { replace: true })
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Login failed')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-sps-cream px-4">
      <Card className="w-full max-w-md overflow-hidden shadow-sm">
        <div className="border-b border-sps-border bg-white px-6 py-5">
          <div className="flex items-center gap-3">
            <img
              src="/favicon.svg"
              alt="SPS Hong Kong logo"
              className="h-14 w-14 rounded-md bg-black object-contain"
            />
            <div>
              <p className="text-[10px] font-semibold uppercase tracking-[0.14em] text-sps-orange">
                St. Patrick&apos;s Society HK
              </p>
              <p className="text-lg font-semibold tracking-wide text-sps-green">SPS CRM</p>
            </div>
          </div>
        </div>
        <CardHeader>
          <CardTitle>Sign in</CardTitle>
          <CardDescription>
            Manage members, sponsors, companies, and deals.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form className="space-y-4" onSubmit={onSubmit}>
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                autoComplete="username"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
            {error ? (
              <p className="rounded-md bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p>
            ) : null}
            <Button type="submit" className="w-full" disabled={submitting}>
              {submitting ? 'Signing in...' : 'Sign in'}
            </Button>
            <p className="text-center text-xs text-sps-muted">
              Default: admin@stpatrickshk.com / changeme
            </p>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
