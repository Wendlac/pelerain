'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { requireAgent } from '@/lib/auth'
import { createClient } from '@/lib/supabase/server'

export type TripFormState = {
  error?: string
  fieldErrors?: Partial<Record<TripField, string>>
}

type TripField =
  | 'departure_city'
  | 'arrival_city'
  | 'departure_time'
  | 'arrival_time'
  | 'price'
  | 'available_seats'
  | 'amenities'

type ParsedTrip = {
  departure_city: string
  arrival_city: string
  departure_time: string // ISO
  arrival_time: string // ISO
  price: number
  available_seats: number
  amenities: string | null
}

/**
 * Parse + validate the form. Returns either { ok: true, trip } or
 * { ok: false, state } so callers can render field-level errors.
 */
function parseTripForm(
  formData: FormData
): { ok: true; trip: ParsedTrip } | { ok: false; state: TripFormState } {
  const errors: Partial<Record<TripField, string>> = {}

  const departure_city = String(formData.get('departure_city') ?? '').trim()
  const arrival_city = String(formData.get('arrival_city') ?? '').trim()
  const departure_time_raw = String(formData.get('departure_time') ?? '').trim()
  const arrival_time_raw = String(formData.get('arrival_time') ?? '').trim()
  const price_raw = String(formData.get('price') ?? '').trim()
  const seats_raw = String(formData.get('available_seats') ?? '').trim()
  const amenities_raw = String(formData.get('amenities') ?? '').trim()

  if (!departure_city) errors.departure_city = 'Ville de départ requise.'
  if (!arrival_city) errors.arrival_city = "Ville d'arrivée requise."
  if (departure_city && arrival_city && departure_city.toLowerCase() === arrival_city.toLowerCase()) {
    errors.arrival_city = 'Doit être différente de la ville de départ.'
  }

  if (!departure_time_raw) errors.departure_time = 'Date+heure de départ requise.'
  if (!arrival_time_raw) errors.arrival_time = 'Date+heure d’arrivée requise.'

  const departure_time = departure_time_raw ? new Date(departure_time_raw) : null
  const arrival_time = arrival_time_raw ? new Date(arrival_time_raw) : null

  if (departure_time && isNaN(departure_time.getTime())) {
    errors.departure_time = 'Date invalide.'
  }
  if (arrival_time && isNaN(arrival_time.getTime())) {
    errors.arrival_time = 'Date invalide.'
  }
  if (
    departure_time &&
    arrival_time &&
    !errors.departure_time &&
    !errors.arrival_time &&
    arrival_time <= departure_time
  ) {
    errors.arrival_time = "L'arrivée doit être après le départ."
  }

  const price = Number(price_raw)
  if (!price_raw || isNaN(price) || price <= 0) {
    errors.price = 'Prix invalide (doit être > 0).'
  }

  const seats = Number(seats_raw)
  if (!seats_raw || !Number.isInteger(seats) || seats < 0) {
    errors.available_seats = 'Nombre de places invalide.'
  }

  if (Object.keys(errors).length > 0) {
    return { ok: false, state: { fieldErrors: errors } }
  }

  return {
    ok: true,
    trip: {
      departure_city,
      arrival_city,
      departure_time: departure_time!.toISOString(),
      arrival_time: arrival_time!.toISOString(),
      price,
      available_seats: seats,
      amenities: amenities_raw || null,
    },
  }
}

/** Create a new trip for the current agent's company. */
export async function createTripAction(
  _prev: TripFormState,
  formData: FormData
): Promise<TripFormState> {
  const agent = await requireAgent()
  if (!agent.company_id) {
    return { error: "Votre compte n'est rattaché à aucune compagnie." }
  }

  const parsed = parseTripForm(formData)
  if (!parsed.ok) return parsed.state

  const supabase = await createClient()
  const { error } = await supabase.from('trips').insert({
    ...parsed.trip,
    company_id: agent.company_id,
    status: 'active',
  })

  if (error) {
    return { error: `Création impossible : ${error.message}` }
  }

  revalidatePath('/trips')
  redirect('/trips?created=1')
}

/** Update an existing trip. RLS guarantees the agent owns it. */
export async function updateTripAction(
  tripId: string,
  _prev: TripFormState,
  formData: FormData
): Promise<TripFormState> {
  const parsed = parseTripForm(formData)
  if (!parsed.ok) return parsed.state

  const supabase = await createClient()
  const { error } = await supabase
    .from('trips')
    .update(parsed.trip)
    .eq('id', tripId)

  if (error) {
    return { error: `Mise à jour impossible : ${error.message}` }
  }

  revalidatePath('/trips')
  revalidatePath(`/trips/${tripId}/edit`)
  redirect('/trips?updated=1')
}

/** Cancel a trip (status → 'cancelled'). Reservations are kept untouched. */
export async function cancelTripAction(tripId: string) {
  const supabase = await createClient()
  const { error } = await supabase
    .from('trips')
    .update({ status: 'cancelled' })
    .eq('id', tripId)

  if (error) throw new Error(error.message)
  revalidatePath('/trips')
}

/** Reactivate a previously cancelled trip. */
export async function reactivateTripAction(tripId: string) {
  const supabase = await createClient()
  const { error } = await supabase
    .from('trips')
    .update({ status: 'active' })
    .eq('id', tripId)

  if (error) throw new Error(error.message)
  revalidatePath('/trips')
}
