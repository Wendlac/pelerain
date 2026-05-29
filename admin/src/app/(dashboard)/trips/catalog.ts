import { createClient } from '@/lib/supabase/server'

/**
 * Helper used by both the create and edit trip pages to load the city and
 * amenity catalogues from Supabase. Keeping it server-side means the form
 * always has the freshest options (e.g. a city added 30s ago appears
 * immediately, no client refetch needed).
 */
export async function loadTripCatalog() {
  const supabase = await createClient()

  const [{ data: cities }, { data: amenities }] = await Promise.all([
    supabase
      .from('cities')
      .select('name, region')
      .eq('is_active', true)
      .order('name'),
    supabase
      .from('amenities')
      .select('label')
      .eq('is_active', true)
      .order('sort_order'),
  ])

  return {
    cities: (cities ?? []) as { name: string; region: string | null }[],
    amenities: (amenities ?? []) as { label: string }[],
  }
}
