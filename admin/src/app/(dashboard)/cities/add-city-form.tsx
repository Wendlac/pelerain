'use client'

import { useActionState, useEffect, useRef } from 'react'
import { Loader2, Plus } from 'lucide-react'
import { createCityAction, type CityFormState } from './actions'

/**
 * Inline form sitting above the cities table. On success, the input is
 * cleared and the table re-renders thanks to `revalidatePath` in the action.
 */
export function AddCityForm() {
  const [state, formAction, pending] = useActionState<CityFormState, FormData>(
    createCityAction,
    undefined
  )

  const formRef = useRef<HTMLFormElement>(null)

  // Reset the inputs after a successful submit (no error returned)
  useEffect(() => {
    if (!pending && !state?.error) {
      formRef.current?.reset()
    }
  }, [pending, state])

  return (
    <div className="rounded-3xl border border-border-light bg-surface p-6 shadow-sm shadow-content/5">
      <h3 className="mb-3 text-sm font-bold text-content">Ajouter une ville</h3>
      <form
        ref={formRef}
        action={formAction}
        className="flex flex-wrap items-end gap-3"
      >
        <div className="flex-1 min-w-[180px]">
          <label htmlFor="name" className="block text-xs font-semibold text-content-tertiary mb-1">
            Nom
          </label>
          <input
            id="name"
            name="name"
            type="text"
            required
            placeholder="Manga"
            className="w-full rounded-2xl border border-border bg-surface px-4 py-2.5 text-sm outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/20"
          />
        </div>
        <div className="flex-1 min-w-[180px]">
          <label htmlFor="region" className="block text-xs font-semibold text-content-tertiary mb-1">
            Région (facultatif)
          </label>
          <input
            id="region"
            name="region"
            type="text"
            placeholder="Centre-Sud"
            className="w-full rounded-2xl border border-border bg-surface px-4 py-2.5 text-sm outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/20"
          />
        </div>
        <button
          type="submit"
          disabled={pending}
          className="inline-flex items-center gap-2 rounded-full bg-primary px-4 py-2.5 text-sm font-bold text-white transition hover:bg-primary-dark disabled:opacity-60"
        >
          {pending ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <Plus className="h-4 w-4" />
          )}
          Ajouter
        </button>
      </form>
      {state?.error && (
        <p className="mt-3 text-xs font-semibold text-error-dark">
          {state.error}
        </p>
      )}
    </div>
  )
}
