import { ChevronLeft } from 'lucide-react'
import Link from 'next/link'
import { TripForm } from '../trip-form'
import { loadTripCatalog } from '../catalog'

export default async function NewTripPage() {
  const { cities, amenities } = await loadTripCatalog()

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
          Nouveau trajet
        </h2>
        <p className="mt-1 text-sm text-content-tertiary">
          Programmez un nouveau départ. Il deviendra visible immédiatement
          dans l'app mobile.
        </p>
      </div>

      <div className="rounded-3xl border border-border-light bg-surface p-6 shadow-sm shadow-content/5">
        <TripForm cities={cities} amenities={amenities} />
      </div>
    </div>
  )
}
