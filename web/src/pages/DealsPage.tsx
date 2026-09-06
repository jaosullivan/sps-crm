import { FormEvent, useCallback, useEffect, useState } from 'react'
import { Pencil, Plus, Trash2 } from 'lucide-react'
import { api, ApiError } from '@/lib/api'
import { formatDate, formatHkd } from '@/lib/utils'
import type { Company, Deal, DealCreate, DealStage } from '@/types'
import { DEAL_STAGES } from '@/types'
import { PageHeader } from '@/components/PageHeader'
import { Modal } from '@/components/Modal'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent } from '@/components/ui/card'

const emptyForm: DealCreate = {
  title: '',
  company_id: null,
  stage: 'lead',
  value_hkd: '',
  contact_name: '',
  contact_email: '',
  expected_close: '',
  notes: '',
}

function toForm(d: Deal): DealCreate {
  return {
    title: d.title,
    company_id: d.company_id ?? null,
    stage: d.stage,
    value_hkd: d.value_hkd ?? '',
    contact_name: d.contact_name ?? '',
    contact_email: d.contact_email ?? '',
    expected_close: d.expected_close ?? '',
    notes: d.notes ?? '',
  }
}

function cleanPayload(form: DealCreate): DealCreate {
  const value =
    form.value_hkd === '' || form.value_hkd === null || form.value_hkd === undefined
      ? null
      : Number(form.value_hkd)
  return {
    title: form.title,
    company_id: form.company_id || null,
    stage: form.stage,
    value_hkd: value !== null && !Number.isNaN(value) ? value : null,
    contact_name: form.contact_name || null,
    contact_email: form.contact_email || null,
    expected_close: form.expected_close || null,
    notes: form.notes || null,
  }
}

export function DealsPage() {
  const [items, setItems] = useState<Deal[]>([])
  const [companies, setCompanies] = useState<Company[]>([])
  const [q, setQ] = useState('')
  const [stageFilter, setStageFilter] = useState<DealStage | ''>('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [open, setOpen] = useState(false)
  const [editing, setEditing] = useState<Deal | null>(null)
  const [form, setForm] = useState<DealCreate>(emptyForm)
  const [saving, setSaving] = useState(false)

  const load = useCallback(async (search?: string, stage?: DealStage | '') => {
    setLoading(true)
    setError(null)
    try {
      const [deals, comps] = await Promise.all([
        api.listDeals({
          q: search || undefined,
          stage: stage || undefined,
        }),
        api.listCompanies(),
      ])
      setItems(deals)
      setCompanies(comps)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Failed to load deals')
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

  const openEdit = (d: Deal) => {
    setEditing(d)
    setForm(toForm(d))
    setOpen(true)
  }

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setSaving(true)
    setError(null)
    try {
      const body = cleanPayload(form)
      if (editing) await api.updateDeal(editing.id, body)
      else await api.createDeal(body)
      setOpen(false)
      await load(q, stageFilter)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  const onDelete = async (d: Deal) => {
    if (!confirm(`Delete deal ${d.title}?`)) return
    try {
      await api.deleteDeal(d.id)
      await load(q, stageFilter)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Delete failed')
    }
  }

  return (
    <div>
      <PageHeader
        title="Deals"
        description="Sponsorship and partnership pipeline."
        actions={
          <Button onClick={openCreate}>
            <Plus className="h-4 w-4" />
            Add deal
          </Button>
        }
      />

      <div className="mb-4 flex flex-wrap gap-2">
        <Input
          placeholder="Search deals…"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') void load(q, stageFilter)
          }}
          className="max-w-sm"
        />
        <Select
          value={stageFilter}
          onChange={(e) => {
            const next = e.target.value as DealStage | ''
            setStageFilter(next)
            void load(q, next)
          }}
          className="w-40"
        >
          <option value="">All stages</option>
          {DEAL_STAGES.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </Select>
        <Button variant="outline" onClick={() => void load(q, stageFilter)}>
          Search
        </Button>
      </div>

      {error ? (
        <p className="mb-4 rounded-md bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p>
      ) : null}

      <Card>
        <CardContent className="overflow-x-auto p-0">
          <table className="w-full min-w-[720px] text-left text-sm">
            <thead className="border-b border-sps-border bg-sps-cream/60 text-xs uppercase tracking-wide text-sps-muted">
              <tr>
                <th className="px-4 py-3 font-medium">Title</th>
                <th className="px-4 py-3 font-medium">Stage</th>
                <th className="px-4 py-3 font-medium">Company</th>
                <th className="px-4 py-3 font-medium">Value</th>
                <th className="px-4 py-3 font-medium">Expected close</th>
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
                    No deals found.
                  </td>
                </tr>
              ) : (
                items.map((d) => (
                  <tr key={d.id} className="border-b border-sps-border last:border-0">
                    <td className="px-4 py-3 font-medium">{d.title}</td>
                    <td className="px-4 py-3 capitalize">{d.stage}</td>
                    <td className="px-4 py-3">{companyName(d.company_id)}</td>
                    <td className="px-4 py-3">{formatHkd(d.value_hkd)}</td>
                    <td className="px-4 py-3">{formatDate(d.expected_close)}</td>
                    <td className="px-4 py-3">
                      <div className="flex justify-end gap-1">
                        <Button variant="ghost" size="sm" onClick={() => openEdit(d)}>
                          <Pencil className="h-3.5 w-3.5" />
                        </Button>
                        <Button variant="ghost" size="sm" onClick={() => void onDelete(d)}>
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
        title={editing ? 'Edit deal' : 'Add deal'}
        onClose={() => setOpen(false)}
        footer={
          <>
            <Button variant="outline" type="button" onClick={() => setOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" form="deal-form" disabled={saving}>
              {saving ? 'Saving…' : 'Save'}
            </Button>
          </>
        }
      >
        <form id="deal-form" className="grid gap-3 sm:grid-cols-2" onSubmit={onSubmit}>
          <div className="space-y-1.5 sm:col-span-2">
            <Label htmlFor="title">Title</Label>
            <Input
              id="title"
              required
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="stage">Stage</Label>
            <Select
              id="stage"
              value={form.stage}
              onChange={(e) =>
                setForm({ ...form, stage: e.target.value as DealStage })
              }
            >
              {DEAL_STAGES.map((s) => (
                <option key={s} value={s}>
                  {s}
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
            <Label htmlFor="value_hkd">Value (HKD)</Label>
            <Input
              id="value_hkd"
              type="number"
              min={0}
              step="0.01"
              value={form.value_hkd ?? ''}
              onChange={(e) => setForm({ ...form, value_hkd: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="expected_close">Expected close</Label>
            <Input
              id="expected_close"
              type="date"
              value={form.expected_close ?? ''}
              onChange={(e) => setForm({ ...form, expected_close: e.target.value })}
            />
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
