'use client'

import { useState, useTransition } from 'react'
import { Loader2, RotateCcw, XCircle } from 'lucide-react'
import { cancelTripAction, reactivateTripAction } from './actions'
import { cn } from '@/lib/cn'

/**
 * Inline Cancel/Reactivate button for the trips table. The label and color
 * flip depending on the current status. A confirm dialog only blocks the
 * destructive case (cancel).
 */
export function TripRowActions({
  tripId,
  status,
  hasReservations,
}: {
  tripId: string
  status: string
  hasReservations: boolean
}) {
  const [pending, startTransition] = useTransition()
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  const cancel = () => {
    if (pending) return
    const warning = hasReservations
      ? 'Ce trajet a des réservations en attente. Si vous l’annulez, les voyageurs garderont leurs billets mais devront être prévenus.\n\nContinuer ?'
      : 'Annuler ce trajet ? Il ne sera plus proposé aux voyageurs.'
    if (!window.confirm(warning)) return

    startTransition(async () => {
      try {
        await cancelTripAction(tripId)
      } catch (e) {
        setErrorMessage(e instanceof Error ? e.message : 'Erreur inconnue')
      }
    })
  }

  const reactivate = () => {
    if (pending) return
    startTransition(async () => {
      try {
        await reactivateTripAction(tripId)
      } catch (e) {
        setErrorMessage(e instanceof Error ? e.message : 'Erreur inconnue')
      }
    })
  }

  if (status === 'cancelled') {
    return (
      <button
        type="button"
        onClick={reactivate}
        disabled={pending}
        className={cn(
          'inline-flex items-center gap-1.5 rounded-full border border-success/30 bg-success/8 px-3 py-1.5 text-xs font-bold text-success-dark transition hover:bg-success/15',
          pending && 'opacity-60'
        )}
        title={errorMessage ?? 'Réactiver le trajet'}
      >
        {pending ? (
          <Loader2 className="h-3.5 w-3.5 animate-spin" />
        ) : (
          <RotateCcw className="h-3.5 w-3.5" />
        )}
        Réactiver
      </button>
    )
  }

  return (
    <button
      type="button"
      onClick={cancel}
      disabled={pending}
      className={cn(
        'inline-flex items-center gap-1.5 rounded-full border border-error/30 bg-error/8 px-3 py-1.5 text-xs font-bold text-error-dark transition hover:bg-error/15',
        pending && 'opacity-60'
      )}
      title={errorMessage ?? 'Annuler le trajet'}
    >
      {pending ? (
        <Loader2 className="h-3.5 w-3.5 animate-spin" />
      ) : (
        <XCircle className="h-3.5 w-3.5" />
      )}
      Annuler
    </button>
  )
}
