'use client'

import { cn } from '@/lib/cn'
import { ChevronDown } from 'lucide-react'

/**
 * Lightweight native `<select>` styled to match the rest of the form fields.
 * For BF's ~15 cities a native dropdown is the simplest, most accessible
 * option — no combobox library needed.
 */
export function SelectField({
  label,
  name,
  defaultValue,
  options,
  placeholder = 'Sélectionner…',
  error,
  helper,
}: {
  label: string
  name: string
  defaultValue?: string
  options: { value: string; label: string }[]
  placeholder?: string
  error?: string
  helper?: string
}) {
  return (
    <div className="space-y-1.5">
      <label htmlFor={name} className="text-sm font-semibold text-content">
        {label}
      </label>
      <div className="relative">
        <select
          id={name}
          name={name}
          defaultValue={defaultValue ?? ''}
          className={cn(
            'w-full appearance-none rounded-2xl border bg-surface px-4 py-3 pr-10 text-sm outline-none transition focus:ring-2',
            error
              ? 'border-error/40 focus:border-error focus:ring-error/15'
              : 'border-border focus:border-primary focus:ring-primary/20'
          )}
        >
          <option value="" disabled>
            {placeholder}
          </option>
          {options.map((o) => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
        <ChevronDown
          className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-content-tertiary"
          aria-hidden
        />
      </div>
      {error && <p className="text-xs font-medium text-error-dark">{error}</p>}
      {!error && helper && (
        <p className="text-xs text-content-tertiary">{helper}</p>
      )}
    </div>
  )
}
