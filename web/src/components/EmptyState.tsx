import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

export function EmptyState({
  title,
  description,
  action,
  className,
}: {
  title: string
  description?: string
  action?: ReactNode
  className?: string
}) {
  return (
    <div
      className={cn(
        'flex flex-col items-center justify-center px-6 py-12 text-center',
        className,
      )}
    >
      <div
        className="mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-sps-green-light ring-1 ring-sps-green-pale"
        aria-hidden
      >
        <svg viewBox="0 0 24 24" className="h-6 w-6 text-sps-orange" fill="currentColor">
          <path d="M12 3.2c1.6 2.2 2.2 4.1 1.8 5.5-.3 1-.9 1.7-1.8 2.2-.9-.5-1.5-1.2-1.8-2.2-.4-1.4.2-3.3 1.8-5.5Z" />
          <path d="M6.2 9.4c2.6.4 4.4 1.4 5.2 2.8.6 1 0.7 2.1.4 3.1-1.1-.2-2.1-.8-2.9-1.7-1.1-1.3-1.8-3-2.7-4.2Z" />
          <path d="M17.8 9.4c-.9 1.2-1.6 2.9-2.7 4.2-.8.9-1.8 1.5-2.9 1.7-.3-1-.2-2.1.4-3.1.8-1.4 2.6-2.4 5.2-2.8Z" />
          <path d="M11.2 14.8c.2 1.6.5 3.2.8 4.8.3-1.6.6-3.2.8-4.8-.5-.1-1.1-.1-1.6 0Z" />
        </svg>
      </div>
      <p className="text-sm font-semibold text-sps-ink">{title}</p>
      {description ? (
        <p className="mt-1 max-w-sm text-sm text-sps-muted">{description}</p>
      ) : null}
      {action ? <div className="mt-4">{action}</div> : null}
    </div>
  )
}
