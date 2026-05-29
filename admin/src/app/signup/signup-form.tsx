'use client'

import { useActionState, useState } from 'react'
import { Loader2 } from 'lucide-react'
import { cn } from '@/lib/cn'
import { signupCompanyAction, type SignupState } from './actions'

/**
 * Two-step look that fits in one form. The buyer reads the section titles
 * and feels guided: "Ma compagnie" first, "Mon compte" second.
 */
export function SignupForm() {
  const [state, formAction, pending] = useActionState<
    SignupState | undefined,
    FormData
  >(signupCompanyAction, undefined)
  const [showPassword, setShowPassword] = useState(false)

  const err = (k: keyof NonNullable<SignupState['fieldErrors']>) =>
    state?.fieldErrors?.[k]

  return (
    <form action={formAction} className="space-y-7">
      {/* ── Company section ─────────────────────────────────────────── */}
      <fieldset className="space-y-4">
        <legend className="text-xs font-bold uppercase tracking-wider text-primary">
          Votre compagnie
        </legend>

        <Field
          label="Nom de la compagnie"
          name="company_name"
          placeholder="Ex. Rahimo Transports"
          autoComplete="organization"
          error={err('company_name')}
        />
        <Field
          label="Téléphone de la compagnie"
          name="company_phone"
          type="tel"
          placeholder="+226 25 31 00 00"
          autoComplete="tel"
          error={err('company_phone')}
        />
        <TextareaField
          label="Description (facultatif)"
          name="company_description"
          placeholder="Présentez votre activité et vos lignes principales en quelques mots."
          rows={3}
        />
      </fieldset>

      {/* ── Admin section ────────────────────────────────────────────── */}
      <fieldset className="space-y-4">
        <legend className="text-xs font-bold uppercase tracking-wider text-primary">
          Votre compte administrateur
        </legend>

        <Field
          label="Votre nom complet"
          name="full_name"
          placeholder="Awa Ouédraogo"
          autoComplete="name"
          error={err('full_name')}
        />
        <Field
          label="Email"
          name="email"
          type="email"
          placeholder="vous@compagnie.bf"
          autoComplete="email"
          error={err('email')}
        />
        <Field
          label="Mot de passe"
          name="password"
          type={showPassword ? 'text' : 'password'}
          placeholder="6 caractères minimum"
          autoComplete="new-password"
          error={err('password')}
          rightAddon={
            <button
              type="button"
              onClick={() => setShowPassword((s) => !s)}
              className="text-xs font-semibold text-content-tertiary hover:text-content"
              tabIndex={-1}
            >
              {showPassword ? 'Masquer' : 'Voir'}
            </button>
          }
        />
      </fieldset>

      {/* Global error banner */}
      {state?.error && (
        <div className="rounded-2xl border border-error/25 bg-error/8 px-4 py-3 text-sm font-medium text-error-dark">
          {state.error}
        </div>
      )}

      {/* Trial reminder */}
      <div className="rounded-2xl border border-primary/15 bg-primary/5 px-4 py-3 text-xs text-content-secondary">
        En créant votre compte, vous démarrez un essai gratuit de{' '}
        <strong className="text-content">14 jours</strong>. Aucune carte
        bancaire n'est demandée. À la fin de l'essai, contactez l'équipe
        Pelerain pour activer votre abonnement.
      </div>

      <button
        type="submit"
        disabled={pending}
        className="inline-flex w-full items-center justify-center gap-2 rounded-full bg-primary px-6 py-3.5 text-sm font-bold text-white transition hover:bg-primary-dark disabled:opacity-60"
      >
        {pending && <Loader2 className="h-4 w-4 animate-spin" />}
        {pending ? 'Création du compte…' : 'Créer mon compte'}
      </button>
    </form>
  )
}

function Field({
  label,
  name,
  type = 'text',
  placeholder,
  autoComplete,
  error,
  rightAddon,
}: {
  label: string
  name: string
  type?: string
  placeholder?: string
  autoComplete?: string
  error?: string
  rightAddon?: React.ReactNode
}) {
  return (
    <div className="space-y-1.5">
      <label htmlFor={name} className="text-sm font-semibold text-content">
        {label}
      </label>
      <div
        className={cn(
          'flex items-center rounded-2xl border bg-surface px-4 transition focus-within:ring-2',
          error
            ? 'border-error/40 focus-within:border-error focus-within:ring-error/15'
            : 'border-border focus-within:border-primary focus-within:ring-primary/20'
        )}
      >
        <input
          id={name}
          name={name}
          type={type}
          placeholder={placeholder}
          autoComplete={autoComplete}
          required
          className="w-full bg-transparent py-3 text-sm outline-none placeholder:text-content-disabled"
        />
        {rightAddon && <span className="ml-2 shrink-0">{rightAddon}</span>}
      </div>
      {error && <p className="text-xs font-medium text-error-dark">{error}</p>}
    </div>
  )
}

function TextareaField({
  label,
  name,
  placeholder,
  rows = 3,
}: {
  label: string
  name: string
  placeholder?: string
  rows?: number
}) {
  return (
    <div className="space-y-1.5">
      <label htmlFor={name} className="text-sm font-semibold text-content">
        {label}
      </label>
      <textarea
        id={name}
        name={name}
        placeholder={placeholder}
        rows={rows}
        className="w-full resize-none rounded-2xl border border-border bg-surface px-4 py-3 text-sm outline-none transition placeholder:text-content-disabled focus:border-primary focus:ring-2 focus:ring-primary/20"
      />
    </div>
  )
}
