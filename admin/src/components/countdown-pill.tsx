'use client'

import { useEffect, useState } from 'react'
import { Timer, TimerOff } from 'lucide-react'
import { cn } from '@/lib/cn'

/**
 * Live countdown showing how long is left in the payment window for a
 * reservation. Colour shifts from violet → orange → red as the deadline
 * approaches, grey once it has lapsed.
 */
export function CountdownPill({ expiresAt }: { expiresAt: string }) {
  const target = new Date(expiresAt).getTime()
  const [now, setNow] = useState(() => Date.now())

  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), 1000)
    return () => clearInterval(id)
  }, [])

  const remainingMs = target - now
  const expired = remainingMs <= 0

  const totalSeconds = Math.max(0, Math.floor(remainingMs / 1000))
  const hours = Math.floor(totalSeconds / 3600)
  const minutes = Math.floor((totalSeconds % 3600) / 60)

  let label: string
  if (expired) label = 'Expirée'
  else if (hours > 0) label = `${hours}h${minutes.toString().padStart(2, '0')}`
  else label = `${minutes}m`

  const variant = expired
    ? 'expired'
    : remainingMs < 30 * 60_000
    ? 'critical'
    : remainingMs < 2 * 3600_000
    ? 'warning'
    : 'ok'

  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-bold whitespace-nowrap',
        variant === 'ok' && 'bg-primary/10 text-primary',
        variant === 'warning' && 'bg-warning/20 text-warning-dark',
        variant === 'critical' && 'bg-error/10 text-error',
        variant === 'expired' && 'bg-surface-neutral text-content-tertiary'
      )}
    >
      {expired ? (
        <TimerOff className="h-3 w-3" />
      ) : (
        <Timer className="h-3 w-3" />
      )}
      {label}
    </span>
  )
}
