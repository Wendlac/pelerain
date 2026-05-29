import { Inbox, Search, Users } from 'lucide-react'
import { requireAgent } from '@/lib/auth'
import { createClient } from '@/lib/supabase/server'
import { CountdownPill } from '@/components/countdown-pill'
import { ConfirmButton } from './confirm-button'
import {
  formatDateLong,
  formatPrice,
  formatTime,
} from '@/lib/format'

export const dynamic = 'force-dynamic' // always read fresh data

type Trip = {
  departure_city: string
  arrival_city: string
  departure_time: string
  arrival_time: string
}

/**
 * Supabase JS may return a related row as either an object or an array
 * depending on FK direction; we treat both shapes uniformly when reading.
 */
type RawReservation = {
  id: string
  reservation_code: string
  status: string
  seats: number
  total_price: number
  created_at: string
  expires_at: string
  trips: Trip | Trip[] | null
}

type Reservation = Omit<RawReservation, 'trips'> & { trips: Trip | null }

function normaliseTrip(raw: Trip | Trip[] | null): Trip | null {
  if (!raw) return null
  return Array.isArray(raw) ? raw[0] ?? null : raw
}

export default async function ReservationsPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; welcome?: string }>
}) {
  // Already gated by the dashboard layout, but call it again to get the
  // company_name for the empty/error message and search context.
  const agent = await requireAgent()
  const { q, welcome } = await searchParams
  const search = q?.trim() ?? ''

  const supabase = await createClient()
  let query = supabase
    .from('reservations')
    .select(
      `
      id, reservation_code, status, seats, total_price, created_at, expires_at,
      trips (departure_city, arrival_city, departure_time, arrival_time)
      `
    )
    .eq('status', 'pending')
    .order('created_at', { ascending: false })

  if (search) {
    query = query.ilike('reservation_code', `%${search}%`)
  }

  const { data, error } = await query
  const reservations: Reservation[] = ((data ?? []) as RawReservation[]).map(
    (r) => ({ ...r, trips: normaliseTrip(r.trips) })
  )

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h2 className="text-3xl font-black tracking-tight text-content">
            Réservations en attente
          </h2>
          <p className="mt-1 text-sm text-content-tertiary">
            {agent.company_name
              ? `Pour la compagnie ${agent.company_name}. Marquez chaque réservation comme payée dès que le client a réglé en agence.`
              : 'Votre compte n’est rattaché à aucune compagnie.'}
          </p>
        </div>

        {/* Search */}
        <form
          action="/reservations"
          className="flex items-center gap-2 rounded-full border border-border bg-surface px-4 py-2"
        >
          <Search className="h-4 w-4 text-content-tertiary" />
          <input
            type="text"
            name="q"
            defaultValue={search}
            placeholder="Code (ex: PEL-A8X3Q)"
            className="w-56 bg-transparent text-sm outline-none placeholder:text-content-disabled"
          />
        </form>
      </div>

      {/* First-login welcome banner (after signup) */}
      {welcome && (
        <div className="rounded-3xl border border-primary/20 bg-primary-surface px-5 py-4 text-sm text-content">
          <p className="font-bold text-primary">
            Bienvenue sur Pelerain, {agent.full_name.split(' ')[0]} 🎉
          </p>
          <p className="mt-1 text-content-secondary">
            Votre compagnie <strong>{agent.company_name}</strong> est créée et
            votre essai gratuit de 14 jours a démarré. Commencez par ajouter
            vos premiers trajets dans l'onglet <em>Trajets</em> — ils
            deviendront immédiatement réservables côté voyageur.
          </p>
        </div>
      )}

      {error && (
        <div className="rounded-2xl border border-error/25 bg-error/8 p-4 text-sm font-medium text-error-dark">
          Erreur de chargement : {error.message}
        </div>
      )}

      {/* Empty state */}
      {!error && reservations.length === 0 && (
        <div className="rounded-3xl border border-border-light bg-surface p-12 text-center">
          <div className="mx-auto mb-4 grid h-14 w-14 place-items-center rounded-full bg-primary-surface text-primary">
            <Inbox className="h-7 w-7" />
          </div>
          <h3 className="text-lg font-bold text-content">
            {search
              ? `Aucune réservation pour « ${search} »`
              : 'Aucune réservation en attente'}
          </h3>
          <p className="mt-1 text-sm text-content-tertiary">
            {search
              ? 'Vérifiez le code saisi ou retirez le filtre pour voir toutes les réservations.'
              : 'Les nouvelles réservations apparaîtront ici dès qu’un voyageur réservera l’un de vos trajets.'}
          </p>
        </div>
      )}

      {/* Table */}
      {reservations.length > 0 && (
        <div className="overflow-hidden rounded-3xl border border-border-light bg-surface shadow-sm shadow-content/5">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border-light bg-surface-elevated/50 text-left text-xs font-bold uppercase tracking-wide text-content-tertiary">
                <th className="px-5 py-3">Code</th>
                <th className="px-5 py-3">Trajet</th>
                <th className="px-5 py-3">Départ</th>
                <th className="px-5 py-3">Passagers</th>
                <th className="px-5 py-3 text-right">Total</th>
                <th className="px-5 py-3">Délai</th>
                <th className="px-5 py-3 text-right">Action</th>
              </tr>
            </thead>
            <tbody>
              {reservations.map((r) => (
                <tr
                  key={r.id}
                  className="border-b border-border-light last:border-b-0 transition hover:bg-primary-surface/30"
                >
                  <td className="px-5 py-4">
                    <span className="rounded-lg bg-primary-surface px-2 py-1 font-mono text-xs font-bold tracking-wider text-primary">
                      {r.reservation_code}
                    </span>
                  </td>
                  <td className="px-5 py-4 font-semibold text-content">
                    {r.trips ? (
                      <>
                        {r.trips.departure_city}{' '}
                        <span className="text-content-tertiary">→</span>{' '}
                        {r.trips.arrival_city}
                      </>
                    ) : (
                      <span className="text-content-tertiary">—</span>
                    )}
                  </td>
                  <td className="px-5 py-4 text-content-secondary">
                    {r.trips ? (
                      <div className="flex flex-col leading-tight">
                        <span className="font-semibold">
                          {formatTime(r.trips.departure_time)}
                        </span>
                        <span className="text-xs text-content-tertiary">
                          {formatDateLong(r.trips.departure_time)}
                        </span>
                      </div>
                    ) : (
                      '—'
                    )}
                  </td>
                  <td className="px-5 py-4">
                    <span className="inline-flex items-center gap-1.5 text-content-secondary">
                      <Users className="h-3.5 w-3.5 text-content-tertiary" />
                      <span className="font-semibold">{r.seats}</span>
                    </span>
                  </td>
                  <td className="px-5 py-4 text-right font-bold text-primary">
                    {formatPrice(Number(r.total_price))}
                  </td>
                  <td className="px-5 py-4">
                    <CountdownPill expiresAt={r.expires_at} />
                  </td>
                  <td className="px-5 py-4 text-right">
                    <ConfirmButton
                      reservationId={r.id}
                      reservationCode={r.reservation_code}
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
