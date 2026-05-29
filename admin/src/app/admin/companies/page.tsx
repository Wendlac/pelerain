import { Building2, Sparkles, Clock, CheckCircle2, AlertCircle, Ban } from 'lucide-react'
import { createClient } from '@/lib/supabase/server'
import { cn } from '@/lib/cn'
import { formatDateLong } from '@/lib/format'
import { CompanyActionsMenu } from './company-actions-menu'
import type { SubscriptionStatus } from '@/lib/auth'

export const dynamic = 'force-dynamic'

type Company = {
  id: string
  name: string
  phone: string | null
  subscription_status: SubscriptionStatus
  trial_ends_at: string | null
  current_period_ends_at: string | null
  plan: string | null
  created_at: string
}

type ProfileRow = { company_id: string | null; role: string }
type TripRow = { company_id: string; status: string; departure_time: string }
type ReservationCountRow = { trip_id: string; status: string }

export default async function AdminCompaniesPage() {
  const supabase = await createClient()

  // Companies — admin sees all rows; the SELECT policy stays open.
  const { data: companies, error } = await supabase
    .from('companies')
    .select(
      'id, name, phone, subscription_status, trial_ends_at, current_period_ends_at, plan, created_at'
    )
    .order('created_at', { ascending: false })

  const list = (companies ?? []) as Company[]

  // Batch-fetch agents & trips so we can show per-company counters.
  // For a few dozen companies these full-table queries are cheap.
  const [{ data: profiles }, { data: trips }, { data: tripsForReservations }] =
    await Promise.all([
      supabase
        .from('profiles')
        .select('company_id, role')
        .in('role', ['agent', 'company_admin']),
      supabase
        .from('trips')
        .select('company_id, status, departure_time'),
      supabase
        .from('trips')
        .select('id, company_id'),
    ])

  // Agents per company
  const agentsByCompany: Record<string, number> = {}
  for (const p of (profiles ?? []) as ProfileRow[]) {
    if (p.company_id) {
      agentsByCompany[p.company_id] = (agentsByCompany[p.company_id] ?? 0) + 1
    }
  }

  // Upcoming active trips per company
  const upcomingByCompany: Record<string, number> = {}
  const nowIso = new Date().toISOString()
  for (const t of (trips ?? []) as TripRow[]) {
    if (t.status === 'active' && t.departure_time > nowIso) {
      upcomingByCompany[t.company_id] =
        (upcomingByCompany[t.company_id] ?? 0) + 1
    }
  }

  // Pending reservations per company (count via trip mapping)
  const tripToCompany: Record<string, string> = {}
  for (const t of (tripsForReservations ?? []) as { id: string; company_id: string }[]) {
    tripToCompany[t.id] = t.company_id
  }
  const { data: reservations } = await supabase
    .from('reservations')
    .select('trip_id, status')
    .eq('status', 'pending')

  const pendingByCompany: Record<string, number> = {}
  for (const r of (reservations ?? []) as ReservationCountRow[]) {
    const cid = tripToCompany[r.trip_id]
    if (cid) {
      pendingByCompany[cid] = (pendingByCompany[cid] ?? 0) + 1
    }
  }

  // ── Metrics ──
  const counts = {
    total: list.length,
    pilot: list.filter((c) => c.subscription_status === 'pilot').length,
    trial: list.filter((c) => c.subscription_status === 'trial').length,
    active: list.filter((c) => c.subscription_status === 'active').length,
    past_due: list.filter((c) => c.subscription_status === 'past_due').length,
    suspended: list.filter((c) => c.subscription_status === 'suspended').length,
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h2 className="text-3xl font-black tracking-tight text-content">
          Console Pelerain · Compagnies
        </h2>
        <p className="mt-1 text-sm text-content-tertiary">
          Toutes les compagnies inscrites sur la plateforme, avec leur statut
          d'abonnement et un accès rapide aux actions de gestion.
        </p>
      </div>

      {/* Metric cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <Metric label="Total" value={counts.total} icon={<Building2 className="h-4 w-4" />} />
        <Metric
          label="Pilotes"
          value={counts.pilot}
          icon={<Sparkles className="h-4 w-4" />}
          tone="primary"
        />
        <Metric
          label="En essai"
          value={counts.trial}
          icon={<Clock className="h-4 w-4" />}
          tone="warning"
        />
        <Metric
          label="Abonnées"
          value={counts.active}
          icon={<CheckCircle2 className="h-4 w-4" />}
          tone="success"
        />
        <Metric
          label="Suspendues"
          value={counts.suspended}
          icon={<Ban className="h-4 w-4" />}
          tone="error"
        />
      </div>

      {error && (
        <div className="rounded-2xl border border-error/25 bg-error/8 p-4 text-sm font-medium text-error-dark">
          Erreur de chargement : {error.message}
        </div>
      )}

      {/* Empty */}
      {!error && list.length === 0 && (
        <div className="rounded-3xl border border-border-light bg-surface p-12 text-center">
          <Building2 className="mx-auto h-10 w-10 text-content-tertiary" />
          <h3 className="mt-3 text-lg font-bold text-content">
            Aucune compagnie
          </h3>
          <p className="mt-1 text-sm text-content-tertiary">
            La première compagnie qui s'inscrira via /signup apparaîtra ici.
          </p>
        </div>
      )}

      {/* Companies table */}
      {list.length > 0 && (
        <div className="overflow-hidden rounded-3xl border border-border-light bg-surface shadow-sm shadow-content/5">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border-light bg-surface-elevated/50 text-left text-xs font-bold uppercase tracking-wide text-content-tertiary">
                <th className="px-5 py-3">Compagnie</th>
                <th className="px-5 py-3">Statut</th>
                <th className="px-5 py-3">Échéance</th>
                <th className="px-5 py-3 text-right">Agents</th>
                <th className="px-5 py-3 text-right">Trajets à venir</th>
                <th className="px-5 py-3 text-right">Résa. en attente</th>
                <th className="px-5 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {list.map((c) => (
                <tr
                  key={c.id}
                  className="border-b border-border-light last:border-b-0 transition hover:bg-primary-surface/30"
                >
                  <td className="px-5 py-4">
                    <div className="flex flex-col leading-tight">
                      <span className="font-bold text-content">{c.name}</span>
                      <span className="text-xs text-content-tertiary">
                        {c.phone ?? <em>—</em>}
                      </span>
                      <span className="mt-0.5 text-[10px] uppercase tracking-wider text-content-tertiary">
                        Inscrite le {formatDateLong(c.created_at)}
                      </span>
                    </div>
                  </td>
                  <td className="px-5 py-4">
                    <StatusBadge status={c.subscription_status} />
                  </td>
                  <td className="px-5 py-4 text-content-secondary">
                    <DeadlineCell company={c} />
                  </td>
                  <td className="px-5 py-4 text-right font-semibold">
                    {agentsByCompany[c.id] ?? 0}
                  </td>
                  <td className="px-5 py-4 text-right font-semibold">
                    {upcomingByCompany[c.id] ?? 0}
                  </td>
                  <td className="px-5 py-4 text-right font-semibold">
                    {pendingByCompany[c.id] ?? 0}
                  </td>
                  <td className="px-5 py-4 text-right">
                    <CompanyActionsMenu
                      companyId={c.id}
                      currentStatus={c.subscription_status}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

function Metric({
  label,
  value,
  icon,
  tone = 'neutral',
}: {
  label: string
  value: number
  icon: React.ReactNode
  tone?: 'neutral' | 'primary' | 'warning' | 'success' | 'error'
}) {
  const ring = {
    neutral: 'bg-surface-neutral text-content-tertiary',
    primary: 'bg-primary/10 text-primary',
    warning: 'bg-warning/20 text-warning-dark',
    success: 'bg-success/10 text-success-dark',
    error: 'bg-error/10 text-error',
  }[tone]

  return (
    <div className="rounded-2xl border border-border-light bg-surface p-4 shadow-sm shadow-content/5">
      <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wide text-content-tertiary">
        <span className={cn('grid h-7 w-7 place-items-center rounded-full', ring)}>
          {icon}
        </span>
        {label}
      </div>
      <p className="mt-2 text-3xl font-black tracking-tight text-content">
        {value}
      </p>
    </div>
  )
}

function StatusBadge({ status }: { status: SubscriptionStatus }) {
  const config: Record<
    SubscriptionStatus,
    { label: string; bg: string; text: string; icon: React.ReactNode }
  > = {
    pilot: {
      label: 'Pilote',
      bg: 'bg-primary/10',
      text: 'text-primary',
      icon: <Sparkles className="h-3 w-3" />,
    },
    trial: {
      label: 'Essai',
      bg: 'bg-warning/20',
      text: 'text-warning-dark',
      icon: <Clock className="h-3 w-3" />,
    },
    active: {
      label: 'Active',
      bg: 'bg-success/10',
      text: 'text-success-dark',
      icon: <CheckCircle2 className="h-3 w-3" />,
    },
    past_due: {
      label: 'Paiement en retard',
      bg: 'bg-error/10',
      text: 'text-error',
      icon: <AlertCircle className="h-3 w-3" />,
    },
    suspended: {
      label: 'Suspendue',
      bg: 'bg-content/10',
      text: 'text-content-tertiary',
      icon: <Ban className="h-3 w-3" />,
    },
  }
  const c = config[status]
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-bold',
        c.bg,
        c.text
      )}
    >
      {c.icon}
      {c.label}
    </span>
  )
}

function DeadlineCell({ company }: { company: Company }) {
  if (company.subscription_status === 'pilot') {
    return <span className="text-content-tertiary">Illimité</span>
  }
  if (company.subscription_status === 'trial' && company.trial_ends_at) {
    const daysLeft = Math.ceil(
      (new Date(company.trial_ends_at).getTime() - Date.now()) / (24 * 3600 * 1000)
    )
    return (
      <div className="flex flex-col leading-tight">
        <span className="font-semibold">
          {formatDateLong(company.trial_ends_at)}
        </span>
        <span
          className={cn(
            'text-xs',
            daysLeft < 0 ? 'text-error font-bold' : 'text-content-tertiary'
          )}
        >
          {daysLeft < 0 ? `${Math.abs(daysLeft)}j de retard` : `${daysLeft}j restants`}
        </span>
      </div>
    )
  }
  if (company.subscription_status === 'active' && company.current_period_ends_at) {
    const daysLeft = Math.ceil(
      (new Date(company.current_period_ends_at).getTime() - Date.now()) /
        (24 * 3600 * 1000)
    )
    return (
      <div className="flex flex-col leading-tight">
        <span className="font-semibold">
          {formatDateLong(company.current_period_ends_at)}
        </span>
        <span className="text-xs text-content-tertiary">
          Renouvellement dans {daysLeft}j
        </span>
      </div>
    )
  }
  return <span className="text-content-tertiary">—</span>
}
