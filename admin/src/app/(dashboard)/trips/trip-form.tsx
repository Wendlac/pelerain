'use client'

import { useActionState } from 'react'
import Link from 'next/link'
import { Loader2 } from 'lucide-react'
import { cn } from '@/lib/cn'
import { SelectField } from '@/components/select-field'
import { TagPicker } from '@/components/tag-picker'
import {
  createTripAction,
  updateTripAction,
  type TripFormState,
} from './actions'

type Defaults = {
  departure_city?: string
  arrival_city?: string
  departure_time?: string
  arrival_time?: string
  price?: number | string
  available_seats?: number | string
  amenities?: string | null
}

type CityOpt = { name: string; region: string | null }
type AmenityOpt = { label: string }

export function TripForm({
  defaults,
  tripId,
  cities,
  amenities,
}: {
  defaults?: Defaults
  tripId?: string
  cities: CityOpt[]
  amenities: AmenityOpt[]
}) {
  const action = tripId
    ? updateTripAction.bind(null, tripId)
    : createTripAction

  const [state, formAction, pending] = useActionState<TripFormState, FormData>(
    action,
    {}
  )

  const fieldErr = (k: keyof NonNullable<TripFormState['fieldErrors']>) =>
    state?.fieldErrors?.[k]

  const cityOptions = cities.map((c) => ({
    value: c.name,
    label: c.region ? `${c.name} (${c.region})` : c.name,
  }))

  const amenityOptions = amenities.map((a) => ({
    value: a.label,
    label: a.label,
  }))

  // Parse the persisted amenities string back into an array of selected labels
  const initialAmenities = (defaults?.amenities ?? '')
    .split(/\s*•\s*/)
    .map((s) => s.trim())
    .filter(Boolean)

  return (
    <form action={formAction} className="space-y-6">
      {state?.error && (
        <div className="rounded-2xl border border-error/25 bg-error/8 px-4 py-3 text-sm font-medium text-error-dark">
          {state.error}
        </div>
      )}

      {/* Cities (dropdowns from the cities catalogue) */}
      <div className="grid gap-5 sm:grid-cols-2">
        <SelectField
          label="Ville de départ"
          name="departure_city"
          defaultValue={defaults?.departure_city}
          options={cityOptions}
          placeholder="Choisir la ville de départ"
          error={fieldErr('departure_city')}
        />
        <SelectField
          label="Ville d'arrivée"
          name="arrival_city"
          defaultValue={defaults?.arrival_city}
          options={cityOptions}
          placeholder="Choisir la ville d'arrivée"
          error={fieldErr('arrival_city')}
          helper={
            cityOptions.length === 0
              ? "Aucune ville n'est encore enregistrée — créez-en sur la page Villes."
              : undefined
          }
        />
      </div>

      {/* Times */}
      <div className="grid gap-5 sm:grid-cols-2">
        <Field
          label="Départ (date + heure)"
          name="departure_time"
          type="datetime-local"
          defaultValue={defaults?.departure_time}
          error={fieldErr('departure_time')}
        />
        <Field
          label="Arrivée (date + heure)"
          name="arrival_time"
          type="datetime-local"
          defaultValue={defaults?.arrival_time}
          error={fieldErr('arrival_time')}
        />
      </div>

      {/* Price + seats */}
      <div className="grid gap-5 sm:grid-cols-2">
        <Field
          label="Prix (FCFA)"
          name="price"
          type="number"
          min={0}
          step={500}
          defaultValue={defaults?.price?.toString()}
          placeholder="7000"
          error={fieldErr('price')}
        />
        <Field
          label="Places disponibles"
          name="available_seats"
          type="number"
          min={0}
          step={1}
          defaultValue={defaults?.available_seats?.toString()}
          placeholder="50"
          error={fieldErr('available_seats')}
        />
      </div>

      {/* Amenities (multi-select tags) */}
      <TagPicker
        label="Services à bord"
        name="amenities"
        options={amenityOptions}
        initialSelected={initialAmenities}
        helper="Sélectionnez les services proposés sur ce trajet. Vous pouvez en ajouter de nouveaux depuis la page Villes (à venir)."
      />

      {/* Actions */}
      <div className="flex flex-wrap items-center justify-end gap-3 border-t border-border-light pt-5">
        <Link
          href="/trips"
          className="rounded-full border border-border px-5 py-2.5 text-sm font-semibold text-content-secondary transition hover:bg-surface-neutral"
        >
          Annuler
        </Link>
        <button
          type="submit"
          disabled={pending}
          className="inline-flex items-center gap-2 rounded-full bg-primary px-6 py-2.5 text-sm font-bold text-white transition hover:bg-primary-dark disabled:opacity-60"
        >
          {pending && <Loader2 className="h-4 w-4 animate-spin" />}
          {tripId ? 'Enregistrer' : 'Créer le trajet'}
        </button>
      </div>
    </form>
  )
}

function Field({
  label,
  name,
  type = 'text',
  defaultValue,
  placeholder,
  error,
  helper,
  min,
  step,
}: {
  label: string
  name: string
  type?: string
  defaultValue?: string
  placeholder?: string
  error?: string
  helper?: string
  min?: number
  step?: number
}) {
  return (
    <div className="space-y-1.5">
      <label htmlFor={name} className="text-sm font-semibold text-content">
        {label}
      </label>
      <input
        id={name}
        name={name}
        type={type}
        defaultValue={defaultValue}
        placeholder={placeholder}
        min={min}
        step={step}
        className={cn(
          'w-full rounded-2xl border bg-surface px-4 py-3 text-sm outline-none transition focus:ring-2',
          error
            ? 'border-error/40 focus:border-error focus:ring-error/15'
            : 'border-border focus:border-primary focus:ring-primary/20'
        )}
      />
      {error && <p className="text-xs font-medium text-error-dark">{error}</p>}
      {!error && helper && (
        <p className="text-xs text-content-tertiary">{helper}</p>
      )}
    </div>
  )
}
