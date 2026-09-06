import { FormEvent, useCallback, useEffect, useState } from 'react'
import { Pencil, Plus, Trash2 } from 'lucide-react'
import { api, ApiError } from '@/lib/api'
import { formatDate } from '@/lib/utils'
import type { Member, MemberCreate, MemberStatus } from '@/types'
import { MEMBER_STATUSES } from '@/types'
import { PageHeader } from '@/components/PageHeader'
import { Modal } from '@/components/Modal'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent } from '@/components/ui/card'

const emptyForm: MemberCreate = {
  first_name: '',
  last_name: '',
  email: '',
  phone: '',
  company_name: '',
  status: 'active',
  green_card_number: '',
  joined_on: '',
  notes: '',
}

function toForm(m: Member): MemberCreate {
  return {
    first_name: m.first_name,
    last_name: m.last_name,
    email: m.email,
    phone: m.phone ?? '',
    company_name: m.company_name ?? '',
    status: m.status,
    green_card_number: m.green_card_number ?? '',
    joined_on: m.joined_on ?? '',
    notes: m.notes ?? '',
  }
}

function cleanPayload(form: MemberCreate): MemberCreate {
  return {
    ...form,
    phone: form.phone || null,
    company_name: form.company_name || null,
    green_card_number: form.green_card_number || null,
    joined_on: form.joined_on || null,
    notes: form.notes || null,
  }
}

export function MembersPage() {
  const [items, setItems] = useState<Member[]>([])
  const [q, setQ] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [open, setOpen] = useState(false)
  const [editing, setEditing] = useState<Member | null>(null)
  const [form, setForm] = useState<MemberCreate>(emptyForm)
  const [saving, setSaving] = useState(false)

  const load = useCallback(async (search?: string) => {
    setLoading(true)
    setError(null)
    try {
      setItems(await api.listMembers(search))
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Failed to load members')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const openCreate = () => {
    setEditing(null)
    setForm(emptyForm)
    setOpen(true)
  }

  const openEdit = (m: Member) => {
    setEditing(m)
    setForm(toForm(m))
    setOpen(true)
  }

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setSaving(true)
    setError(null)
    try {
      const body = cleanPayload(form)
      if (editing) {
        await api.updateMember(editing.id, body)
      } else {
        await api.createMember(body)
      }
      setOpen(false)
      await load(q)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  const onDelete = async (m: Member) => {
    if (!confirm(`Delete member ${m.first_name} ${m.last_name}?`)) return
    try {
      await api.deleteMember(m.id)
      await load(q)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Delete failed')
    }
  }

  return (
    <div>
      <PageHeader
        title="Members"
        description="Society membership records."
        actions={
          <Button onClick={openCreate}>
            <Plus className="h-4 w-4" />
            Add member
          </Button>
        }
      />

      <div className="mb-4 flex gap-2">
        <Input
          placeholder="Search members…"
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
          <table className="w-full min-w-[640px] text-left text-sm">
            <thead className="border-b border-sps-border bg-sps-cream/60 text-xs uppercase tracking-wide text-sps-muted">
              <tr>
                <th className="px-4 py-3 font-medium">Name</th>
                <th className="px-4 py-3 font-medium">Email</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium">Company</th>
                <th className="px-4 py-3 font-medium">Joined</th>
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
                    No members found.
                  </td>
                </tr>
              ) : (
                items.map((m) => (
                  <tr key={m.id} className="border-b border-sps-border last:border-0">
                    <td className="px-4 py-3 font-medium">
                      {m.first_name} {m.last_name}
                    </td>
                    <td className="px-4 py-3 text-sps-muted">{m.email}</td>
                    <td className="px-4 py-3 capitalize">{m.status}</td>
                    <td className="px-4 py-3">{m.company_name || '—'}</td>
                    <td className="px-4 py-3">{formatDate(m.joined_on)}</td>
                    <td className="px-4 py-3">
                      <div className="flex justify-end gap-1">
                        <Button variant="ghost" size="sm" onClick={() => openEdit(m)}>
                          <Pencil className="h-3.5 w-3.5" />
                        </Button>
                        <Button variant="ghost" size="sm" onClick={() => void onDelete(m)}>
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
        title={editing ? 'Edit member' : 'Add member'}
        onClose={() => setOpen(false)}
        footer={
          <>
            <Button variant="outline" type="button" onClick={() => setOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" form="member-form" disabled={saving}>
              {saving ? 'Saving…' : 'Save'}
            </Button>
          </>
        }
      >
        <form id="member-form" className="grid gap-3 sm:grid-cols-2" onSubmit={onSubmit}>
          <div className="space-y-1.5">
            <Label htmlFor="first_name">First name</Label>
            <Input
              id="first_name"
              required
              value={form.first_name}
              onChange={(e) => setForm({ ...form, first_name: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="last_name">Last name</Label>
            <Input
              id="last_name"
              required
              value={form.last_name}
              onChange={(e) => setForm({ ...form, last_name: e.target.value })}
            />
          </div>
          <div className="space-y-1.5 sm:col-span-2">
            <Label htmlFor="email">Email</Label>
            <Input
              id="email"
              type="email"
              required
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="phone">Phone</Label>
            <Input
              id="phone"
              value={form.phone ?? ''}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="status">Status</Label>
            <Select
              id="status"
              value={form.status}
              onChange={(e) =>
                setForm({ ...form, status: e.target.value as MemberStatus })
              }
            >
              {MEMBER_STATUSES.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </Select>
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="company_name">Company</Label>
            <Input
              id="company_name"
              value={form.company_name ?? ''}
              onChange={(e) => setForm({ ...form, company_name: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="green_card_number">Green card #</Label>
            <Input
              id="green_card_number"
              value={form.green_card_number ?? ''}
              onChange={(e) =>
                setForm({ ...form, green_card_number: e.target.value })
              }
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="joined_on">Joined on</Label>
            <Input
              id="joined_on"
              type="date"
              value={form.joined_on ?? ''}
              onChange={(e) => setForm({ ...form, joined_on: e.target.value })}
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
