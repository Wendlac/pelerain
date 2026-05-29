'use client'

import { Sparkles, Calendar } from 'lucide-react'
import { cn } from '@/lib/cn'
import type { SubscriptionStatus } from '@/lib/auth'

/**
 * Tiny pill next to the agent name showing the subscription state.
 * - pilot     → discreet violet "Pilote"
 * - trial     → orange with days left countdown
 * - active    → hidden (no need to clutter — it's the normal state)
 * - past_due  → red warning
 * - suspended → never shown here (the user would be on /billing/locked)
 */
export function SubscriptionBadge({
  status,
  trialEndsAt,
  currentPeriodEndsAt,
}: {
  status: SubscriptionStatus | null
  trialEndsAt: string | null
  currentPeriodEndsAt: string | null
}) {
  if (!status) return null

  if (status === 'pilot') {
    return (
      <span className="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-primary">
        <Sparkles className="h-3 w-3" />
        Pilote
      </span>
    )
  }

  if (status === 'trial' && trialEndsAt) {
    const daysLeft = Math.max(
      0,
      Math.ceil(
        (new Date(trialEndsAt).getTime() - Date.now()) / (24 * 3600 * 1000)
      )
    )
    return (
      <span
        className={cn(
          'inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider',
          daysLeft <= 3
            ? 'bg-error/10 text-error'
            : 'bg-warning/20 text-warning-dark'
        )}
      >
        <Calendar className="h-3 w-3" />
        Essai · {daysLeft}j
      </span>
    )
  }

  if (status === 'past_due') {
    return (
      <span className="inline-flex items-center gap-1 rounded-full bg-error/10 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-error">
        Paiement en retard
      </span>
    )
  }

  // active: surface only when getting close to expiry (< 7 days)
  if (status === 'active' && currentPeriodEndsAt) {
    const daysLeft = Math.ceil(
      (new Date(currentPeriodEndsAt).getTime() - Date.now()) /
        (24 * 3600 * 1000)
    )
    if (daysLeft > 0 && daysLeft <= 7) {
      return (
        <span className="inline-flex items-center gap-1 rounded-full bg-warning/20 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-warning-dark">
          <Calendar className="h-3 w-3" />
          Renouvellement · {daysLeft}j
        </span>
      )
    }
  }

  return null
}
