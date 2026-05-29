'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'

export type ConfirmResult =
  | { ok: true; code: string }
  | { ok: false; error: string }

/**
 * Marks a pending reservation as confirmed (= cashed in at the agency).
 * RLS already guarantees the agent can only update reservations belonging
 * to their company, so we don't re-check the company match in code.
 *
 * Returns a structured result so the client component can show a toast.
 */
export async function confirmReservation(
  reservationId: string
): Promise<ConfirmResult> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { ok: false, error: 'Session expirée. Reconnectez-vous.' }

  const { data, error } = await supabase
    .from('reservations')
    .update({
      status: 'confirmed',
      confirmed_at: new Date().toISOString(),
      confirmed_by: user.id,
    })
    .eq('id', reservationId)
    .eq('status', 'pending') // optimistic concurrency: don't overwrite already-handled rows
    .select('reservation_code')
    .single()

  if (error) {
    return {
      ok: false,
      error:
        error.message?.includes('No rows')
          ? "Cette réservation a déjà été traitée ou annulée."
          : 'Impossible de confirmer. Réessayez.',
    }
  }

  revalidatePath('/reservations')
  return { ok: true, code: data.reservation_code }
}
