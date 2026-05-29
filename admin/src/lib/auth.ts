import { redirect } from 'next/navigation'
import { createClient } from './supabase/server'

export type SubscriptionStatus =
  | 'pilot'
  | 'trial'
  | 'active'
  | 'past_due'
  | 'suspended'

export type AgentProfile = {
  id: string
  email: string | null
  full_name: string
  role: string
  company_id: string | null
  company_name: string | null
  // SaaS subscription context — copied from the company row, mirrored here
  // so pages don't need a separate query.
  subscription_status: SubscriptionStatus | null
  trial_ends_at: string | null
  current_period_ends_at: string | null
}

/**
 * Statuses that grant access to the back-office.
 * `past_due` is included as a soft grace period — once a real payment
 * provider is wired in we can tighten this.
 */
const ACTIVE_SUB_STATUSES: SubscriptionStatus[] = [
  'pilot',
  'trial',
  'active',
  'past_due',
]

/**
 * Resolves the current user's full profile + their company's subscription
 * context. Performs every access check the back-office needs:
 *
 * 1. Logged-in?              → no → /login
 * 2. Role is agent/admin?    → no → /login?error=access_denied (after signOut)
 * 3. Company is attached?    → no → /billing/locked?reason=no_company
 * 4. Subscription is live?   → no → /billing/locked?reason=<status>
 *
 * The Pelerain super-admin (role='admin') bypasses checks 3 and 4 because
 * they administer the platform itself, not a customer company.
 */
export async function requireAgent(): Promise<AgentProfile> {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const { data: profile } = await supabase
    .from('profiles')
    .select(
      `
      id, email, full_name, role, company_id,
      companies (
        name, subscription_status, trial_ends_at, current_period_ends_at
      )
      `
    )
    .eq('id', user.id)
    .single()

  const allowedRoles = ['agent', 'company_admin', 'admin']
  if (!profile || !allowedRoles.includes(profile.role)) {
    await supabase.auth.signOut()
    redirect('/login?error=access_denied')
  }

  // Flatten the joined company row (Supabase exposes it as either object or array)
  const company = Array.isArray(profile.companies)
    ? profile.companies[0]
    : (profile.companies as {
        name: string
        subscription_status: SubscriptionStatus
        trial_ends_at: string | null
        current_period_ends_at: string | null
      } | null)

  const agent: AgentProfile = {
    id: profile.id,
    email: profile.email,
    full_name: profile.full_name,
    role: profile.role,
    company_id: profile.company_id,
    company_name: company?.name ?? null,
    subscription_status: company?.subscription_status ?? null,
    trial_ends_at: company?.trial_ends_at ?? null,
    current_period_ends_at: company?.current_period_ends_at ?? null,
  }

  // Pelerain super-admin bypasses subscription checks
  if (agent.role === 'admin') return agent

  if (!agent.company_id) {
    redirect('/billing/locked?reason=no_company')
  }

  if (
    !agent.subscription_status ||
    !ACTIVE_SUB_STATUSES.includes(agent.subscription_status)
  ) {
    redirect(`/billing/locked?reason=${agent.subscription_status ?? 'unknown'}`)
  }

  // Detect expired trial / period (the DB function gates the mobile side; we
  // duplicate the check here for the back-office to redirect cleanly).
  const now = Date.now()
  if (
    agent.subscription_status === 'trial' &&
    agent.trial_ends_at &&
    new Date(agent.trial_ends_at).getTime() < now
  ) {
    redirect('/billing/locked?reason=trial_expired')
  }
  if (
    agent.subscription_status === 'active' &&
    agent.current_period_ends_at &&
    new Date(agent.current_period_ends_at).getTime() < now
  ) {
    redirect('/billing/locked?reason=period_expired')
  }

  return agent
}

/**
 * Looser version of requireAgent: only checks login + role, not subscription.
 * Used by /billing pages so a locked agent can still log in, read the
 * lockout message, and sign out — without ending up in a redirect loop.
 */
export async function requireAgentEvenIfLocked(): Promise<AgentProfile> {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const { data: profile } = await supabase
    .from('profiles')
    .select(
      `
      id, email, full_name, role, company_id,
      companies (
        name, subscription_status, trial_ends_at, current_period_ends_at
      )
      `
    )
    .eq('id', user.id)
    .single()

  const allowedRoles = ['agent', 'company_admin', 'admin']
  if (!profile || !allowedRoles.includes(profile.role)) {
    await supabase.auth.signOut()
    redirect('/login?error=access_denied')
  }

  const company = Array.isArray(profile.companies)
    ? profile.companies[0]
    : (profile.companies as {
        name: string
        subscription_status: SubscriptionStatus
        trial_ends_at: string | null
        current_period_ends_at: string | null
      } | null)

  return {
    id: profile.id,
    email: profile.email,
    full_name: profile.full_name,
    role: profile.role,
    company_id: profile.company_id,
    company_name: company?.name ?? null,
    subscription_status: company?.subscription_status ?? null,
    trial_ends_at: company?.trial_ends_at ?? null,
    current_period_ends_at: company?.current_period_ends_at ?? null,
  }
}
