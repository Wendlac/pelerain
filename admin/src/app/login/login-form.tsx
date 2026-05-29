'use client'

import { useActionState } from 'react'
import { Loader2 } from 'lucide-react'
import { loginAction, type LoginState } from './actions'

export function LoginForm({ initialError }: { initialError?: string }) {
  const [state, formAction, pending] = useActionState<LoginState, FormData>(
    loginAction,
    initialError ? { error: initialError } : undefined
  )

  return (
    <form action={formAction} className="space-y-5">
      <div className="space-y-1.5">
        <label
          htmlFor="email"
          className="text-sm font-semibold text-content"
        >
          Email
        </label>
        <input
          id="email"
          name="email"
          type="email"
          required
          autoComplete="email"
          placeholder="agent@compagnie.bf"
          className="w-full rounded-2xl border border-border bg-surface px-4 py-3 text-sm outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/20"
        />
      </div>

      <div className="space-y-1.5">
        <label
          htmlFor="password"
          className="text-sm font-semibold text-content"
        >
          Mot de passe
        </label>
        <input
          id="password"
          name="password"
          type="password"
          required
          autoComplete="current-password"
          className="w-full rounded-2xl border border-border bg-surface px-4 py-3 text-sm outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/20"
        />
      </div>

      {state?.error && (
        <div className="rounded-xl border border-error/25 bg-error/8 px-4 py-3 text-sm font-medium text-error-dark">
          {state.error}
        </div>
      )}

      <button
        type="submit"
        disabled={pending}
        className="flex w-full items-center justify-center gap-2 rounded-full bg-primary px-6 py-3.5 text-sm font-bold text-white transition hover:bg-primary-dark disabled:opacity-60"
      >
        {pending && <Loader2 className="h-4 w-4 animate-spin" />}
        {pending ? 'Connexion…' : 'Se connecter'}
      </button>

      <p className="text-center text-xs text-content-tertiary">
        Accès réservé aux agents des compagnies partenaires.
        <br />
        Contactez votre administrateur pour obtenir un compte.
      </p>
    </form>
  )
}
