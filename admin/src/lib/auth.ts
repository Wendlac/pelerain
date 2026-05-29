import { redirect } from 'next/navigation'
import { createClient } from './supabase/server'

export type AgentProfile = {
  id: string
  email: string | null
  full_name: string
  role: string
  company_id: string | null
  company_name: string | null
}

/**
 * Resolves the current user's full profile (joined with company name).
 * If the user isn't logged in OR their role isn't one of the allowed values,
 * redirects to /login. This is the gatekeeper used by every page in the
 * dashboard.
 */
export async function requireAgent(): Promise<AgentProfile> {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const { data: profile } = await supabase
    .from('profiles')
    .select('id, email, full_name, role, company_id, companies(name)')
    .eq('id', user.id)
    .single()

  const allowedRoles = ['agent', 'company_admin', 'admin']
  if (!profile || !allowedRoles.includes(profile.role)) {
    // Sign them out so they don't loop back here on next nav, then send them
    // to /login with an explanatory query string we can surface in the UI.
    await supabase.auth.signOut()
    redirect('/login?error=access_denied')
  }

  // The Supabase types treat `companies` as a relation array; flatten it.
  const company = Array.isArray(profile.companies)
    ? profile.companies[0]
    : (profile.companies as { name: string } | null)

  return {
    id: profile.id,
    email: profile.email,
    full_name: profile.full_name,
    role: profile.role,
    company_id: profile.company_id,
    company_name: company?.name ?? null,
  }
}
