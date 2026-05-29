import { ChevronLeft } from 'lucide-react'
import Link from 'next/link'
import { notFound } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { TripForm } from '../../trip-form'
import { loadTripCatalog } from '../../catalog'

/**
 * Trip edit page. The agent can only land here if RLS lets them SELECT the
 * row — anything else returns notFound.
 */
export default async function EditTripPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const supabase = await createClient()
  const [{ data: trip }, catalog] = await Promise.all([
    supabase
      .from('trips')
      .select(
        'id, departure_city, arrival_city, departure_time, arrival_time, price, available_seats, amenities, status'
      )
      .eq('id', id)
      .maybeSingle(),
    loadTripCatalog(),
  ])

  if (!trip) notFound()

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <Link
        href="/trips"
        className="inline-flex items-center gap-1 text-sm font-semibold text-content-tertiary transition hover:text-content"
      >
        <ChevronLeft className="h-4 w-4" /> Retour aux trajets
      </Link>

      <div>
        <h2 className="text-3xl font-black tracking-tight text-content">
          Modifier le trajet
        </h2>
        <p className="mt-1 text-sm text-content-tertiary">
          {trip.departure_city} → {trip.arrival_city}
        </p>
      </div>

      <div className="rounded-3xl border border-border-light bg-surface p-6 shadow-sm shadow-content/5">
        <TripForm
          tripId={trip.id}
          cities={catalog.cities}
          amenities={catalog.amenities}
          defaults={{
            departure_city: trip.departure_city,
            arrival_city: trip.arrival_city,
            departure_time: toLocalInput(trip.departure_time),
            duration_hours: durationBetween(
              trip.departure_time,
              trip.arrival_time
            ),
            price: trip.price,
            available_seats: trip.available_seats,
            amenities: trip.amenities,
          }}
        />
      </div>
    </div>
  )
}

/**
 * `<input type="datetime-local">` expects "YYYY-MM-DDTHH:mm" in the user's
 * local time zone. Postgres returns ISO with `Z`; convert here without using
 * libs.
 */
function toLocalInput(iso: string): string {
  const d = new Date(iso)
  const pad = (n: number) => n.toString().padStart(2, '0')
  return (
    `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}` +
    `T${pad(d.getHours())}:${pad(d.getMinutes())}`
  )
}

/**
 * Difference between two ISO timestamps, in hours. Rounded to 1 decimal
 * (matches the form's `step={0.5}`) so a trip stored as 5h30m comes back
 * as 5.5 instead of 5.499999.
 */
function durationBetween(startIso: string, endIso: string): number {
  const start = new Date(startIso).getTime()
  const end = new Date(endIso).getTime()
  const hours = (end - start) / 3_600_000
  return Math.round(hours * 10) / 10
}
