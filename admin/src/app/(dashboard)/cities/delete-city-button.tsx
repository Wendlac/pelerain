'use client'

import { useState, useTransition } from 'react'
import { Loader2, Trash2 } from 'lucide-react'
import { deleteCityAction } from './actions'

export function DeleteCityButton({
  cityId,
  cityName,
}: {
  cityId: string
  cityName: string
}) {
  const [pending, startTransition] = useTransition()
  const [error, setError] = useState<string | null>(null)

  const handleClick = () => {
    if (pending) return
    if (!window.confirm(`Supprimer la ville « ${cityName} » ?`)) return

    startTransition(async () => {
      try {
        await deleteCityAction(cityId, cityName)
      } catch (e) {
        const msg = e instanceof Error ? e.message : 'Erreur inconnue'
        setError(msg)
        window.alert(msg) // simple feedback — toast lib can come later
      }
    })
  }

  return (
    <button
      type="button"
      onClick={handleClick}
      disabled={pending}
      title={error ?? `Supprimer ${cityName}`}
      className="inline-flex items-center gap-1.5 rounded-full border border-error/30 bg-error/8 px-3 py-1.5 text-xs font-bold text-error-dark transition hover:bg-error/15 disabled:opacity-60"
    >
      {pending ? (
        <Loader2 className="h-3.5 w-3.5 animate-spin" />
      ) : (
        <Trash2 className="h-3.5 w-3.5" />
      )}
      Supprimer
    </button>
  )
}
