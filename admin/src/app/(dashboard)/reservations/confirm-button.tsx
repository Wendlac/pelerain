'use client'

import { useState, useTransition } from 'react'
import { Check, Loader2 } from 'lucide-react'
import { confirmReservation } from './actions'

/**
 * Inline action button on each row. Click → optional confirm dialog →
 * server action → toast feedback.
 */
export function ConfirmButton({
  reservationId,
  reservationCode,
}: {
  reservationId: string
  reservationCode: string
}) {
  const [pending, startTransition] = useTransition()
  const [feedback, setFeedback] = useState<
    | { kind: 'success'; message: string }
    | { kind: 'error'; message: string }
    | null
  >(null)

  const handleClick = () => {
    if (pending) return
    const ok = window.confirm(
      `Confirmer l'encaissement de la réservation ${reservationCode} ?\n\nLe client doit avoir présenté son code et payé en agence.`
    )
    if (!ok) return

    startTransition(async () => {
      const result = await confirmReservation(reservationId)
      if (result.ok) {
        setFeedback({
          kind: 'success',
          message: `Réservation ${result.code} marquée comme payée ✓`,
        })
      } else {
        setFeedback({ kind: 'error', message: result.error })
      }
      // The toast auto-dismisses after a few seconds
      setTimeout(() => setFeedback(null), 4000)
    })
  }

  return (
    <>
      <button
        type="button"
        onClick={handleClick}
        disabled={pending}
        className="inline-flex items-center gap-1.5 rounded-full bg-success px-3 py-1.5 text-xs font-bold text-white shadow-sm transition hover:bg-success-dark disabled:opacity-60"
      >
        {pending ? (
          <Loader2 className="h-3.5 w-3.5 animate-spin" />
        ) : (
          <Check className="h-3.5 w-3.5" />
        )}
        Encaisser
      </button>

      {feedback && (
        <div
          role="status"
          className={`fixed bottom-6 right-6 z-50 max-w-sm rounded-2xl px-4 py-3 text-sm font-semibold text-white shadow-xl ${
            feedback.kind === 'success' ? 'bg-success' : 'bg-error'
          }`}
        >
          {feedback.message}
        </div>
      )}
    </>
  )
}
