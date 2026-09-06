import { FormEvent, useCallback, useEffect, useState } from 'react'
import { Pencil, Plus, Trash2 } from 'lucide-react'
import { api, ApiError } from '@/lib/api'
import type { Company, CompanyCreate } from '@/types'
import { PageHeader } from '@/components/PageHeader'
import { Modal } from '@/components/Modal'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent } from '@/components/ui/card'
import { EmptyState } from '@/components/EmptyState'

const emptyForm: CompanyCreate = {
  name: '',
  website: '',
  industry: '',
  notes: '',
}

function toForm(c: Company): CompanyCreate {
  return {
    name: c.name,
    website: c.website ?? '',
    industry: c.industry ?? '',
    notes: c.notes ?? '',
  }
}

function cleanPayload(form: CompanyCreate): CompanyCreate {
  return {
    name: form.name,
    website: form.website || null,
    industry: form.industry || null,
    notes: form.notes || null,
  }
}

export function CompaniesPage() {
  const [items, setItems] = useState<Company[]>([])
  const [q, setQ] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [open, setOpen] = useState(false)
  const [editing, setEditing] = useState<Company | null>(null)
  const [form, setForm] = useState<CompanyCreate>(emptyForm)
  const [saving, setSaving] = useState(false)

  const load = useCallback(async (search?: string) => {
    setLoading(true)
    setError(null)
    try {
      setItems(await api.listCompanies(search))
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Failed to load companies')
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

  const openEdit = (c: Company) => {
    setEditing(c)
    setForm(toForm(c))
    setOpen(true)
  }

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setSaving(true)
    setError(null)
    try {
      const body = cleanPayload(form)
      if (editing) await api.updateCompany(editing.id, body)
      else await api.createCompany(body)
      setOpen(false)
      await load(q)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  const onDelete = async (c: Company) => {
    if (!confirm(`Delete company ${c.name}?`)) return
    try {
      await api.deleteCompany(c.id)
      await load(q)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Delete failed')
    }
  }

  return (
    <div>
      <PageHeader
        title="Companies"
        description="Organisations linked to sponsors and deals."
        actions={
          <Button onClick={openCreate}>
            <Plus className="h-4 w-4" />
            Add company
          </Button>
        }
      />

      <div className="mb-4 flex gap-2">
        <Input
          placeholder="Search companies..."
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
          <table className="w-full min-w-[560px] text-left text-sm">
            <thead className="border-b border-sps-border bg-sps-cream/60 text-xs uppercase tracking-wide text-sps-muted">
              <tr>
                <th className="px-4 py-3 font-medium">Name</th>
                <th className="px-4 py-3 font-medium">Industry</th>
                <th className="px-4 py-3 font-medium">Website</th>
                <th className="px-4 py-3 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={4} className="px-4 py-8 text-center text-sps-muted">
                    Loading...
                  </td>
                </tr>
              ) : items.length === 0 ? (
                <tr>
                  <td colSpan={4} className="p-0">
                    <EmptyState
                      title="No companies yet"
                      description="Add organisations linked to sponsors and deals."
                      action={
                        <Button onClick={openCreate}>
                          <Plus className="h-4 w-4" />
                          Add company
                        </Button>
                      }
                    />
                  </td>
                </tr>
              ) : (
                items.map((c) => (
                  <tr key={c.id} className="border-b border-sps-border last:border-0">
                    <td className="px-4 py-3 font-medium">{c.name}</td>
                    <td className="px-4 py-3">{c.industry || '-'}</td>
                    <td className="px-4 py-3 text-sps-muted">
                      {c.website ? (
                        <a
                          href={c.website}
                          target="_blank"
                          rel="noreferrer"
                          className="text-sps-green hover:underline"
                        >
                          {c.website}
                        </a>
                      ) : (
                        '-'
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex justify-end gap-1">
                        <Button variant="ghost" size="sm" onClick={() => openEdit(c)}>
                          <Pencil className="h-3.5 w-3.5" />
                        </Button>
                        <Button variant="ghost" size="sm" onClick={() => void onDelete(c)}>
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
        title={editing ? 'Edit company' : 'Add company'}
        onClose={() => setOpen(false)}
        footer={
          <>
            <Button variant="outline" type="button" onClick={() => setOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" form="company-form" disabled={saving}>
              {saving ? 'Saving...' : 'Save'}
            </Button>
          </>
        }
      >
        <form id="company-form" className="grid gap-3" onSubmit={onSubmit}>
          <div className="space-y-1.5">
            <Label htmlFor="name">Name</Label>
            <Input
              id="name"
              required
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="website">Website</Label>
            <Input
              id="website"
              type="url"
              placeholder="https://"
              value={form.website ?? ''}
              onChange={(e) => setForm({ ...form, website: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="industry">Industry</Label>
            <Input
              id="industry"
              value={form.industry ?? ''}
              onChange={(e) => setForm({ ...form, industry: e.target.value })}
            />
          </div>
          <div className="space-y-1.5">
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
