'use server'

import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'

export type LoginState = { error?: string } | undefined

/**
 * Server action handling the login form. On success, redirects to
 * /reservations. On failure, returns an error to be rendered next to the form.
 */
export async function loginAction(
  _prevState: LoginState,
  formData: FormData
): Promise<LoginState> {
  const email = String(formData.get('email') ?? '').trim()
  const password = String(formData.get('password') ?? '')

  if (!email || !password) {
    return { error: 'Email et mot de passe requis.' }
  }

  const supabase = await createClient()
  const { error } = await supabase.auth.signInWithPassword({ email, password })

  if (error) {
    return { error: frenchAuthError(error.message) }
  }

  // Verify the user is actually authorised for the back-office
  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) return { error: 'Connexion impossible.' }

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  const allowed = ['agent', 'company_admin', 'admin']
  if (!profile || !allowed.includes(profile.role)) {
    await supabase.auth.signOut()
    return {
      error: "Ce compte n'a pas accès au back-office des compagnies.",
    }
  }

  redirect('/reservations')
}

export async function logoutAction() {
  const supabase = await createClient()
  await supabase.auth.signOut()
  redirect('/login')
}

function frenchAuthError(raw: string): string {
  const lower = raw.toLowerCase()
  if (lower.includes('invalid login')) return 'Email ou mot de passe incorrect.'
  if (lower.includes('network')) return 'Pas de connexion internet.'
  if (lower.includes('email not confirmed')) {
    return 'Email non confirmé. Contactez votre administrateur.'
  }
  return raw
}
