import { FormEvent, useCallback, useEffect, useState } from 'react'
import { Pencil, Plus, Trash2 } from 'lucide-react'
import { api, ApiError } from '@/lib/api'
import { formatHkd } from '@/lib/utils'
import type { Company, Sponsor, SponsorCreate, SponsorTier } from '@/types'
import { SPONSOR_TIERS } from '@/types'
import { PageHeader } from '@/components/PageHeader'
import { Modal } from '@/components/Modal'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent } from '@/components/ui/card'

const emptyForm: SponsorCreate = {
  name: '',
  company_id: null,
  tier: 'gold',
  contact_name: '',
  contact_email: '',
  contact_phone: '',
  amount_hkd: '',
  year: null,
  event_name: '',
  starts_on: '',
  ends_on: '',
  notes: '',
}

function toForm(s: Sponsor): SponsorCreate {
  return {
    name: s.name,
    company_id: s.company_id ?? null,
    tier: s.tier,
    contact_name: s.contact_name ?? '',
    contact_email: s.contact_email ?? '',
    contact_phone: s.contact_phone ?? '',
    amount_hkd: s.amount_hkd ?? '',
    year: s.year ?? null,
    event_name: s.event_name ?? '',
    starts_on: s.starts_on ?? '',
    ends_on: s.ends_on ?? '',
    notes: s.notes ?? '',
  }
}

function cleanPayload(form: SponsorCreate): SponsorCreate {
  const amount =
    form.amount_hkd === '' || form.amount_hkd === null || form.amount_hkd === undefined
      ? null
      : Number(form.amount_hkd)
  return {
    name: form.name,
    company_id: form.company_id || null,
    tier: form.tier,
    contact_name: form.contact_name || null,
    contact_email: form.contact_email || null,
    contact_phone: form.contact_phone || null,
    amount_hkd: amount !== null && !Number.isNaN(amount) ? amount : null,
    year: form.year || null,
    event_name: form.event_name || null,
    starts_on: form.starts_on || null,
    ends_on: form.ends_on || null,
    notes: form.notes || null,
  }
}

export function SponsorsPage() {
  const [items, setItems] = useState<Sponsor[]>([])
  const [companies, setCompanies] = useState<Company[]>([])
  const [q, setQ] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [open, setOpen] = useState(false)
  const [editing, setEditing] = useState<Sponsor | null>(null)
  const [form, setForm] = useState<SponsorCreate>(emptyForm)
  const [saving, setSaving] = useState(false)

  const load = useCallback(async (search?: string) => {
    setLoading(true)
    setError(null)
    try {
      const [sponsors, comps] = await Promise.all([
        api.listSponsors(search),
        api.listCompanies(),
      ])
      setItems(sponsors)
      setCompanies(comps)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Failed to load sponsors')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const companyName = (id?: number | null) =>
    id ? companies.find((c) => c.id === id)?.name || `#${id}` : '—'

  const openCreate = () => {
    setEditing(null)
    setForm(emptyForm)
    setOpen(true)
  }

  const openEdit = (s: Sponsor) => {
    setEditing(s)
    setForm(toForm(s))
    setOpen(true)
  }

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setSaving(true)
    setError(null)
    try {
      const body = cleanPayload(form)
      if (editing) await api.updateSponsor(editing.id, body)
      else await api.createSponsor(body)
      setOpen(false)
      await load(q)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  const onDelete = async (s: Sponsor) => {
    if (!confirm(`Delete sponsor ${s.name}?`)) return
    try {
      await api.deleteSponsor(s.id)
      await load(q)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Delete failed')
    }
  }

  return (
    <div>
      <PageHeader
        title="Sponsors"
        description="Sponsorships and tiers."
        actions={
          <Button onClick={openCreate}>
            <Plus className="h-4 w-4" />
            Add sponsor
          </Button>
        }
      />

      <div className="mb-4 flex gap-2">
        <Input
          placeholder="Search sponsors…"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') void load(q)
          }}
          className="max-w-sm"
        />
        <Button variant="outline" onClick={() => void load(q)}>
          Search
        </Button>
      </div>

      {error ? (
        <p className="mb-4 rounded-md bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p>
      ) : null}

      <Card>
        <CardContent className="overflow-x-auto p-0">
          <table className="w-full min-w-[700px] text-left text-sm">
            <thead className="border-b border-sps-border bg-sps-cream/60 text-xs uppercase tracking-wide text-sps-muted">
              <tr>
                <th className="px-4 py-3 font-medium">Name</th>
                <th className="px-4 py-3 font-medium">Tier</th>
                <th className="px-4 py-3 font-medium">Company</th>
                <th className="px-4 py-3 font-medium">Amount</th>
                <th className="px-4 py-3 font-medium">Year</th>
                <th className="px-4 py-3 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-4 py-8 text-center text-sps-muted">
                    Loading…
                  </td>
                </tr>
              ) : items.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-8 text-center text-sps-muted">
                    No sponsors found.
                  </td>
                </tr>
              ) : (
                items.map((s) => (
                  <tr key={s.id} className="border-b border-sps-border last:border-0">
                    <td className="px-4 py-3 font-medium">{s.name}</td>
                    <td className="px-4 py-3 capitalize">{s.tier.replace('_', ' ')}</td>
                    <td className="px-4 py-3">{companyName(s.company_id)}</td>
                    <td className="px-4 py-3">{formatHkd(s.amount_hkd)}</td>
                    <td className="px-4 py-3">{s.year ?? '—'}</td>
                    <td className="px-4 py-3">
                      <div className="flex justify-end gap-1">
                        <Button variant="ghost" size="sm" onClick={() => openEdit(s)}>
                          <Pencil className="h-3.5 w-3.5" />
                        </Button>
                        <Button variant="ghost" size="sm" onClick={() => void onDelete(s)}>
                          <Trash2 className="h-3.5 w-3.5 text-red-600" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </CardContent>
      </Card>

      <Modal
        open={open}
        title={editing ? 'Edit sponsor' : 'Add sponsor'}
        onClose={() => setOpen(false)}
        footer={
          <>
            <Button variant="outline" type="button" onClick={() => setOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" form="sponsor-form" disabled={saving}>
              {saving ? 'Saving…' : 'Save'}
            </Button>
          </>
        }
      >
        <form id="sponsor-form" className="grid gap-3 sm:grid-cols-2" onSubmit={onSubmit}>
          <div className="space-y-1.5 sm:col-span-2">
            <Label htmlFor="name">Name</Label>
            <Input
              id="name"
              required
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="tier">Tier</Label>
            <Select
              id="tier"
              value={form.tier}
              onChange={(e) =>
                setForm({ ...form, tier: e.target.value as SponsorTier })
              }
            >
              {SPONSOR_TIERS.map((t) => (
                <option key={t} value={t}>
                  {t.replace('_', ' ')}
                </option>
              ))}
            </Select>
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="company_id">Company</Label>
            <Select
              id="company_id"
              value={form.company_id ?? ''}
              onChange={(e) =>
                setForm({
                  ...form,
                  company_id: e.target.value ? Number(e.target.value) : null,
                })
              }
            >
              <option value="">None</option>
              {companies.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </Select>
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="contact_name">Contact name</Label>
            <Input
              id="contact_name"
              value={form.contact_name ?? ''}
              onChange={(e) => setForm({ ...form, contact_name: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="contact_email">Contact email</Label>
            <Input
              id="contact_email"
              type="email"
              value={form.contact_email ?? ''}
              onChange={(e) => setForm({ ...form, contact_email: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="contact_phone">Contact phone</Label>
            <Input
              id="contact_phone"
              value={form.contact_phone ?? ''}
              onChange={(e) => setForm({ ...form, contact_phone: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="amount_hkd">Amount (HKD)</Label>
            <Input
              id="amount_hkd"
              type="number"
              min={0}
              step="0.01"
              value={form.amount_hkd ?? ''}
              onChange={(e) => setForm({ ...form, amount_hkd: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="year">Year</Label>
            <Input
              id="year"
              type="number"
              value={form.year ?? ''}
              onChange={(e) =>
                setForm({
                  ...form,
                  year: e.target.value ? Number(e.target.value) : null,
                })
              }
            />
          </div>
          <div className="space-y-1.5 sm:col-span-2">
            <Label htmlFor="event_name">Event</Label>
            <Input
              id="event_name"
              value={form.event_name ?? ''}
              onChange={(e) => setForm({ ...form, event_name: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="starts_on">Starts on</Label>
            <Input
              id="starts_on"
              type="date"
              value={form.starts_on ?? ''}
              onChange={(e) => setForm({ ...form, starts_on: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="ends_on">Ends on</Label>
            <Input
              id="ends_on"
              type="date"
              value={form.ends_on ?? ''}
              onChange={(e) => setForm({ ...form, ends_on: e.target.value })}
            />
          </div>
          <div className="space-y-1.5 sm:col-span-2">
            <Label htmlFor="notes">Notes</Label>
            <Textarea
              id="notes"
              value={form.notes ?? ''}
              onChange={(e) => setForm({ ...form, notes: e.target.value })}
            />
          </div>
        </form>
      </Modal>
    </div>
  )
}
