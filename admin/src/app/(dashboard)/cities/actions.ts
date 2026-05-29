'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'

export type CityFormState = { error?: string } | undefined

/** Create a new city. Name is forced to unique by the DB. */
export async function createCityAction(
  _prev: CityFormState,
  formData: FormData
): Promise<CityFormState> {
  const name = String(formData.get('name') ?? '').trim()
  const region = String(formData.get('region') ?? '').trim() || null

  if (!name || name.length < 2) {
    return { error: 'Nom de ville requis (2 caractères min).' }
  }

  const supabase = await createClient()
  const { error } = await supabase
    .from('cities')
    .insert({ name, region, is_active: true })

  if (error) {
    if (error.code === '23505') {
      return { error: `« ${name} » existe déjà.` }
    }
    return { error: `Impossible de créer la ville : ${error.message}` }
  }

  revalidatePath('/cities')
  revalidatePath('/trips/new')
  return undefined
}

/**
 * Delete a city. Refuses if any trip references it — that protects the
 * referential integrity even though we don't have an FK constraint on the
 * trips.departure/arrival_city columns (they're free text for backward
 * compatibility with the mobile app).
 */
export async function deleteCityAction(cityId: string, cityName: string) {
  const supabase = await createClient()

  const { count } = await supabase
    .from('trips')
    .select('id', { count: 'exact', head: true })
    .or(`departure_city.eq.${cityName},arrival_city.eq.${cityName}`)

  if ((count ?? 0) > 0) {
    throw new Error(
      `Impossible de supprimer « ${cityName} » : ${count} trajet(s) y font référence.`
    )
  }

  const { error } = await supabase.from('cities').delete().eq('id', cityId)
  if (error) throw new Error(error.message)
  revalidatePath('/cities')
  revalidatePath('/trips/new')
}
