'use client'

import { useState } from 'react'
import { Check } from 'lucide-react'
import { cn } from '@/lib/cn'

/**
 * Multi-select chip picker. The selected labels are joined with ' • ' and
 * shipped as a single hidden input value, so the server action keeps a
 * plain string column (compatible with the mobile app's display).
 */
export function TagPicker({
  label,
  name,
  options,
  initialSelected = [],
  helper,
}: {
  label: string
  name: string
  options: { value: string; label: string }[] // value === label here
  initialSelected?: string[]
  helper?: string
}) {
  const [selected, setSelected] = useState<Set<string>>(
    () => new Set(initialSelected)
  )

  const toggle = (value: string) => {
    setSelected((prev) => {
      const next = new Set(prev)
      if (next.has(value)) next.delete(value)
      else next.add(value)
      return next
    })
  }

  // Preserve the catalogue order in the hidden value
  const serialised = options
    .map((o) => o.value)
    .filter((v) => selected.has(v))
    .join(' • ')

  return (
    <div className="space-y-2">
      <div>
        <p className="text-sm font-semibold text-content">{label}</p>
        {helper && (
          <p className="text-xs text-content-tertiary mt-0.5">{helper}</p>
        )}
      </div>
      <input type="hidden" name={name} value={serialised} />
      <div className="flex flex-wrap gap-2">
        {options.map((o) => {
          const active = selected.has(o.value)
          return (
            <button
              key={o.value}
              type="button"
              onClick={() => toggle(o.value)}
              className={cn(
                'inline-flex items-center gap-1.5 rounded-full border px-3.5 py-1.5 text-xs font-bold transition',
                active
                  ? 'border-primary bg-primary text-white shadow-sm'
                  : 'border-border bg-surface text-content-secondary hover:border-primary/40 hover:bg-primary-surface/40 hover:text-primary'
              )}
            >
              {active && <Check className="h-3 w-3" />}
              {o.label}
            </button>
          )
        })}
      </div>
    </div>
  )
}
