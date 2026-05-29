import { Bus, Pencil, Plus } from 'lucide-react'
import Link from 'next/link'
import { requireAgent } from '@/lib/auth'
import { createClient } from '@/lib/supabase/server'
import { cn } from '@/lib/cn'
import { formatDateLong, formatPrice, formatTime } from '@/lib/format'
import { TripRowActions } from './trip-row-actions'

export const dynamic = 'force-dynamic'

type StatusFilter = 'upcoming' | 'past' | 'cancelled' | 'all'

type Trip = {
  id: string
  departure_city: string
  arrival_city: string
  departure_time: string
  arrival_time: string
  price: number
  available_seats: number
  status: string
  amenities: string | null
}

type ReservationStat = {
  trip_id: string
  seats: number
  status: string
}

export default async function TripsPage({
  searchParams,
}: {
  searchParams: Promise<{ filter?: StatusFilter; created?: string; updated?: string }>
}) {
  const agent = await requireAgent()
  const { filter = 'upcoming', created, updated } = await searchParams

  const supabase = await createClient()
  const nowIso = new Date().toISOString()

  let query = supabase
    .from('trips')
    .select(
      'id, departure_city, arrival_city, departure_time, arrival_time, price, available_seats, status, amenities'
    )
    .order('departure_time', { ascending: filter !== 'past' })

  // Apply the date/status filter
  if (filter === 'upcoming') {
    query = query.gte('departure_time', nowIso).eq('status', 'active')
  } else if (filter === 'past') {
    query = query.lt('departure_time', nowIso)
  } else if (filter === 'cancelled') {
    query = query.eq('status', 'cancelled')
  }

  const { data: trips, error } = await query
  const list = (trips ?? []) as Trip[]

  // Batch-fetch seat counts (pending + confirmed reservations) for all
  // returned trips, in one query, so the table can show fill rate.
  const tripIds = list.map((t) => t.id)
  let soldSeatsByTrip: Record<string, number> = {}
  let activeRes: Record<string, boolean> = {}

  if (tripIds.length > 0) {
    const { data: resData } = await supabase
      .from('reservations')
      .select('trip_id, seats, status')
      .in('trip_id', tripIds)
      .in('status', ['pending', 'confirmed'])

    for (const r of (resData ?? []) as ReservationStat[]) {
      soldSeatsByTrip[r.trip_id] = (soldSeatsByTrip[r.trip_id] ?? 0) + r.seats
      activeRes[r.trip_id] = true
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h2 className="text-3xl font-black tracking-tight text-content">
            Trajets
          </h2>
          <p className="mt-1 text-sm text-content-tertiary">
            {agent.company_name
              ? `Programmation des départs ${agent.company_name}. Toute modification est instantanément reflétée côté voyageur.`
              : "Votre compte n'est rattaché à aucune compagnie."}
          </p>
        </div>

        <Link
          href="/trips/new"
          className="inline-flex items-center gap-2 rounded-full bg-primary px-4 py-2.5 text-sm font-bold text-white shadow-sm transition hover:bg-primary-dark"
        >
          <Plus className="h-4 w-4" />
          Nouveau trajet
        </Link>
      </div>

      {/* Banners */}
      {created && (
        <div className="rounded-2xl border border-success/25 bg-success/8 px-4 py-3 text-sm font-semibold text-success-dark">
          Trajet créé avec succès ✓
        </div>
      )}
      {updated && (
        <div className="rounded-2xl border border-success/25 bg-success/8 px-4 py-3 text-sm font-semibold text-success-dark">
          Trajet mis à jour ✓
        </div>
      )}

      {/* Filter tabs */}
      <div className="flex flex-wrap gap-2 rounded-full bg-surface p-1.5 shadow-sm shadow-content/5 sm:inline-flex">
        <FilterTab current={filter} value="upcoming" label="À venir" />
        <FilterTab current={filter} value="past" label="Passés" />
        <FilterTab current={filter} value="cancelled" label="Annulés" />
        <FilterTab current={filter} value="all" label="Tous" />
      </div>

      {error && (
        <div className="rounded-2xl border border-error/25 bg-error/8 p-4 text-sm font-medium text-error-dark">
          Erreur de chargement : {error.message}
        </div>
      )}

      {/* Empty */}
      {!error && list.length === 0 && (
        <div className="rounded-3xl border border-border-light bg-surface p-12 text-center">
          <div className="mx-auto mb-4 grid h-14 w-14 place-items-center rounded-full bg-primary-surface text-primary">
            <Bus className="h-7 w-7" />
          </div>
          <h3 className="text-lg font-bold text-content">Aucun trajet</h3>
          <p className="mt-1 text-sm text-content-tertiary">
            {filter === 'upcoming'
              ? "Aucun départ à venir. Cliquez sur « Nouveau trajet » pour en programmer un."
              : 'Aucun trajet ne correspond à ce filtre.'}
          </p>
        </div>
      )}

      {/* Table */}
      {list.length > 0 && (
        <div className="overflow-hidden rounded-3xl border border-border-light bg-surface shadow-sm shadow-content/5">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border-light bg-surface-elevated/50 text-left text-xs font-bold uppercase tracking-wide text-content-tertiary">
                <th className="px-5 py-3">Trajet</th>
                <th className="px-5 py-3">Départ</th>
                <th className="px-5 py-3 text-right">Prix</th>
                <th className="px-5 py-3">Places (vendues / dispo)</th>
                <th className="px-5 py-3">Statut</th>
                <th className="px-5 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {list.map((t) => {
                const sold = soldSeatsByTrip[t.id] ?? 0
                const total = sold + t.available_seats
                const fill = total > 0 ? sold / total : 0
                const isPast = new Date(t.departure_time) < new Date()

                return (
                  <tr
                    key={t.id}
                    className="border-b border-border-light last:border-b-0 transition hover:bg-primary-surface/30"
                  >
                    <td className="px-5 py-4 font-semibold text-content">
                      {t.departure_city}{' '}
                      <span className="text-content-tertiary">→</span>{' '}
                      {t.arrival_city}
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex flex-col leading-tight">
                        <span className="font-semibold text-content">
                          {formatTime(t.departure_time)}
                        </span>
                        <span className="text-xs text-content-tertiary">
                          {formatDateLong(t.departure_time)}
                        </span>
                      </div>
                    </td>
                    <td className="px-5 py-4 text-right font-bold text-primary">
                      {formatPrice(Number(t.price))}
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className="h-1.5 w-24 overflow-hidden rounded-full bg-surface-neutral">
                          <div
                            className={cn(
                              'h-full rounded-full transition-all',
                              fill >= 0.9
                                ? 'bg-error'
                                : fill >= 0.6
                                ? 'bg-warning-dark'
                                : 'bg-success'
                            )}
                            style={{ width: `${Math.round(fill * 100)}%` }}
                          />
                        </div>
                        <span className="text-xs font-semibold text-content-secondary whitespace-nowrap">
                          {sold} / {t.available_seats}
                        </span>
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <StatusBadge status={t.status} isPast={isPast} />
                    </td>
                    <td className="px-5 py-4">
                      <div className="flex items-center justify-end gap-2">
                        <Link
                          href={`/trips/${t.id}/edit`}
                          className="inline-flex items-center gap-1.5 rounded-full border border-border bg-surface px-3 py-1.5 text-xs font-bold text-content-secondary transition hover:border-primary/40 hover:bg-primary-surface/40 hover:text-primary"
                        >
                          <Pencil className="h-3.5 w-3.5" />
                          Modifier
                        </Link>
                        <TripRowActions
                          tripId={t.id}
                          status={t.status}
                          hasReservations={!!activeRes[t.id]}
                        />
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

function FilterTab({
  current,
  value,
  label,
}: {
  current: StatusFilter
  value: StatusFilter
  label: string
}) {
  const active = current === value
  return (
    <Link
      href={value === 'upcoming' ? '/trips' : `/trips?filter=${value}`}
      className={cn(
        'rounded-full px-4 py-1.5 text-sm font-semibold transition',
        active
          ? 'bg-primary text-white'
          : 'text-content-tertiary hover:bg-surface-neutral hover:text-content'
      )}
    >
      {label}
    </Link>
  )
}

function StatusBadge({ status, isPast }: { status: string; isPast: boolean }) {
  if (status === 'cancelled') {
    return (
      <span className="inline-block rounded-full bg-error/10 px-2.5 py-1 text-xs font-bold text-error">
        Annulé
      </span>
    )
  }
  if (isPast) {
    return (
      <span className="inline-block rounded-full bg-surface-neutral px-2.5 py-1 text-xs font-bold text-content-tertiary">
        Passé
      </span>
    )
  }
  return (
    <span className="inline-block rounded-full bg-success/10 px-2.5 py-1 text-xs font-bold text-success-dark">
      Actif
    </span>
  )
}
