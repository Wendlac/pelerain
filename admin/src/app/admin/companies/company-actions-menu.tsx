'use client'

import { useState, useTransition } from 'react'
import {
  Ban,
  CheckCircle2,
  ChevronDown,
  Clock,
  Loader2,
  Sparkles,
} from 'lucide-react'
import { cn } from '@/lib/cn'
import {
  activateAsPilotAction,
  activatePaidAction,
  startTrialAction,
  suspendCompanyAction,
  type AdminActionResult,
} from './actions'

/**
 * Inline dropdown rendered on each company row. Each menu item is wrapped
 * in a useTransition so the row stays interactive while the RPC runs and
 * gives the user a spinner.
 */
export function CompanyActionsMenu({
  companyId,
  currentStatus,
}: {
  companyId: string
  currentStatus: string
}) {
  const [open, setOpen] = useState(false)
  const [pending, startTransition] = useTransition()
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  const run = async (
    label: string,
    fn: () => Promise<AdminActionResult>,
    confirmText?: string
  ) => {
    if (confirmText && !window.confirm(confirmText)) return
    setOpen(false)
    setErrorMessage(null)
    startTransition(async () => {
      const result = await fn()
      if (!result.ok) {
        setErrorMessage(`${label} : ${result.error}`)
      }
    })
  }

  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        disabled={pending}
        className={cn(
          'inline-flex items-center gap-1.5 rounded-full border border-border bg-surface px-3 py-1.5 text-xs font-bold transition',
          pending
            ? 'opacity-60'
            : 'hover:border-primary/40 hover:bg-primary-surface/40 hover:text-primary'
        )}
      >
        {pending ? (
          <Loader2 className="h-3.5 w-3.5 animate-spin" />
        ) : (
          <ChevronDown className="h-3.5 w-3.5" />
        )}
        Actions
      </button>

      {open && (
        <>
          {/* Click-outside backdrop */}
          <button
            type="button"
            aria-hidden
            tabIndex={-1}
            className="fixed inset-0 z-30 cursor-default"
            onClick={() => setOpen(false)}
          />
          <div className="absolute right-0 top-full z-40 mt-1.5 w-60 overflow-hidden rounded-2xl border border-border-light bg-surface shadow-xl shadow-content/10">
            <MenuItem
              icon={<Sparkles className="h-3.5 w-3.5" />}
              label="Activer en pilote"
              hint="Gratuit illimité"
              disabled={currentStatus === 'pilot'}
              onClick={() =>
                run('Activation pilote', () =>
                  activateAsPilotAction(companyId)
                )
              }
            />
            <MenuItem
              icon={<Clock className="h-3.5 w-3.5" />}
              label="Démarrer un essai 14j"
              onClick={() =>
                run('Essai 14j', () => startTrialAction(companyId, 14))
              }
            />
            <MenuItem
              icon={<Clock className="h-3.5 w-3.5" />}
              label="Démarrer un essai 30j"
              onClick={() =>
                run('Essai 30j', () => startTrialAction(companyId, 30))
              }
            />
            <MenuItem
              icon={<CheckCircle2 className="h-3.5 w-3.5" />}
              label="Activer +30 jours"
              hint="Abonnement payé"
              onClick={() =>
                run('Activation payée', () =>
                  activatePaidAction(companyId, 30)
                )
              }
            />
            <div className="my-1 border-t border-border-light" />
            <MenuItem
              icon={<Ban className="h-3.5 w-3.5" />}
              label="Suspendre"
              destructive
              disabled={currentStatus === 'suspended'}
              onClick={() =>
                run(
                  'Suspension',
                  () => suspendCompanyAction(companyId),
                  "Suspendre cette compagnie ? Ses agents seront immédiatement bloqués et ses trajets disparaîtront de l'app voyageur."
                )
              }
            />
          </div>
        </>
      )}

      {errorMessage && (
        <p className="absolute right-0 top-full mt-2 max-w-xs rounded-xl bg-error/10 px-3 py-1.5 text-xs font-semibold text-error-dark shadow-sm">
          {errorMessage}
        </p>
      )}
    </div>
  )
}

function MenuItem({
  icon,
  label,
  hint,
  destructive = false,
  disabled = false,
  onClick,
}: {
  icon: React.ReactNode
  label: string
  hint?: string
  destructive?: boolean
  disabled?: boolean
  onClick: () => void
}) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className={cn(
        'flex w-full items-center gap-2.5 px-3.5 py-2 text-left text-xs font-semibold transition',
        disabled
          ? 'cursor-not-allowed text-content-disabled'
          : destructive
          ? 'text-error-dark hover:bg-error/10'
          : 'text-content-secondary hover:bg-primary-surface/40 hover:text-primary'
      )}
    >
      <span className="shrink-0">{icon}</span>
      <span className="flex-1">{label}</span>
      {hint && (
        <span className="text-[10px] font-medium uppercase tracking-wide text-content-tertiary">
          {hint}
        </span>
      )}
    </button>
  )
}
