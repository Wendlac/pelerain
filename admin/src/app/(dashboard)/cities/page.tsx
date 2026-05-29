import { MapPin } from 'lucide-react'
import { createClient } from '@/lib/supabase/server'
import { AddCityForm } from './add-city-form'
import { DeleteCityButton } from './delete-city-button'

export const dynamic = 'force-dynamic'

type City = {
  id: string
  name: string
  region: string | null
  is_active: boolean
}

export default async function CitiesPage() {
  const supabase = await createClient()

  // Cities ordered alphabetically — simple list, no pagination yet.
  const { data: cities } = await supabase
    .from('cities')
    .select('id, name, region, is_active')
    .order('name')

  // Count trips per city, in one query. We aggregate both departure and
  // arrival in JS since `or` filters can't be grouped easily.
  const { data: trips } = await supabase
    .from('trips')
    .select('departure_city, arrival_city')

  const countByCity: Record<string, number> = {}
  for (const t of trips ?? []) {
    countByCity[t.departure_city] = (countByCity[t.departure_city] ?? 0) + 1
    countByCity[t.arrival_city] = (countByCity[t.arrival_city] ?? 0) + 1
  }

  const list = (cities ?? []) as City[]

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h2 className="text-3xl font-black tracking-tight text-content">
          Villes
        </h2>
        <p className="mt-1 text-sm text-content-tertiary">
          Catalogue partagé entre toutes les compagnies. Les villes ajoutées
          ici deviennent immédiatement sélectionnables dans le formulaire de
          trajet.
        </p>
      </div>

      <AddCityForm />

      {/* Empty */}
      {list.length === 0 && (
        <div className="rounded-3xl border border-border-light bg-surface p-12 text-center">
          <div className="mx-auto mb-4 grid h-14 w-14 place-items-center rounded-full bg-primary-surface text-primary">
            <MapPin className="h-7 w-7" />
          </div>
          <h3 className="text-lg font-bold text-content">Aucune ville</h3>
          <p className="mt-1 text-sm text-content-tertiary">
            Ajoutez votre première ville pour pouvoir créer des trajets.
          </p>
        </div>
      )}

      {/* Table */}
      {list.length > 0 && (
        <div className="overflow-hidden rounded-3xl border border-border-light bg-surface shadow-sm shadow-content/5">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border-light bg-surface-elevated/50 text-left text-xs font-bold uppercase tracking-wide text-content-tertiary">
                <th className="px-5 py-3">Ville</th>
                <th className="px-5 py-3">Région</th>
                <th className="px-5 py-3 text-right">Utilisée par</th>
                <th className="px-5 py-3 text-right">Action</th>
              </tr>
            </thead>
            <tbody>
              {list.map((c) => {
                const count = countByCity[c.name] ?? 0
                return (
                  <tr
                    key={c.id}
                    className="border-b border-border-light last:border-b-0 transition hover:bg-primary-surface/30"
                  >
                    <td className="px-5 py-4 font-semibold text-content">
                      <span className="inline-flex items-center gap-2">
                        <MapPin className="h-4 w-4 text-content-tertiary" />
                        {c.name}
                      </span>
                    </td>
                    <td className="px-5 py-4 text-content-secondary">
                      {c.region ?? <span className="text-content-tertiary">—</span>}
                    </td>
                    <td className="px-5 py-4 text-right text-content-secondary">
                      {count > 0 ? (
                        <span className="font-semibold">
                          {count} trajet{count > 1 ? 's' : ''}
                        </span>
                      ) : (
                        <span className="text-content-tertiary">Aucun</span>
                      )}
                    </td>
                    <td className="px-5 py-4 text-right">
                      <DeleteCityButton cityId={c.id} cityName={c.name} />
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
