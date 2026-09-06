import type { ReactNode } from 'react'
import { Button } from '@/components/ui/button'

export function Modal({
  open,
  title,
  children,
  onClose,
  footer,
}: {
  open: boolean
  title: string
  children: ReactNode
  onClose: () => void
  footer?: ReactNode
}) {
  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <button
        type="button"
        className="absolute inset-0 bg-black/40"
        aria-label="Close dialog"
        onClick={onClose}
      />
      <div
        role="dialog"
        aria-modal="true"
        className="relative z-10 max-h-[90vh] w-full max-w-lg overflow-auto rounded-lg border border-sps-border bg-white shadow-xl"
      >
        <div className="flex items-center justify-between border-b border-sps-border px-5 py-4">
          <h2 className="text-lg font-semibold text-sps-ink">{title}</h2>
          <Button variant="ghost" size="sm" onClick={onClose} type="button">
            Close
          </Button>
        </div>
        <div className="px-5 py-4">{children}</div>
        {footer ? (
          <div className="flex justify-end gap-2 border-t border-sps-border px-5 py-4">
            {footer}
          </div>
        ) : null}
      </div>
    </div>
  )
}
