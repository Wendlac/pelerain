'use server'

import { revalidatePath } from 'next/cache'
import { createClient } from '@/lib/supabase/server'
import type { SubscriptionStatus } from '@/lib/auth'

export type AdminActionResult =
  | { ok: true }
  | { ok: false; error: string }

/**
 * Calls the SECURITY DEFINER RPC. Centralises every subscription state
 * change so the audit trail stays clean (the RPC could later emit events,
 * write to an `admin_actions` table, etc.).
 */
async function setSubscription(
  companyId: string,
  status: SubscriptionStatus,
  untilDays: number | null,
  plan: string | null
): Promise<AdminActionResult> {
  const supabase = await createClient()
  const { error } = await supabase.rpc('admin_set_company_subscription', {
    p_company_id: companyId,
    p_status: status,
    p_until_days: untilDays,
    p_plan: plan,
  })

  if (error) {
    return { ok: false, error: error.message }
  }

  revalidatePath('/admin/companies')
  return { ok: true }
}

export async function activateAsPilotAction(
  companyId: string
): Promise<AdminActionResult> {
  return setSubscription(companyId, 'pilot', null, 'pilot')
}

export async function startTrialAction(
  companyId: string,
  days = 14
): Promise<AdminActionResult> {
  return setSubscription(companyId, 'trial', days, 'trial')
}

export async function activatePaidAction(
  companyId: string,
  days = 30
): Promise<AdminActionResult> {
  return setSubscription(companyId, 'active', days, 'monthly')
}

export async function suspendCompanyAction(
  companyId: string
): Promise<AdminActionResult> {
  return setSubscription(companyId, 'suspended', null, null)
}
