'use server'

import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'

export type SignupState = {
  error?: string
  fieldErrors?: Partial<
    Record<
      | 'company_name'
      | 'company_phone'
      | 'full_name'
      | 'email'
      | 'password',
      string
    >
  >
}

/**
 * Onboards a new transport company end-to-end:
 *
 * 1. Validate every form field
 * 2. supabase.auth.signUp() with the admin's email + password
 * 3. If email confirmation is required by the project (no session), fall
 *    back to signInWithPassword. Mirrors the mobile auth flow so both sides
 *    behave the same way regardless of the Supabase project settings.
 * 4. supabase.rpc('signup_company') — atomically creates the company row
 *    AND promotes the brand-new profile to company_admin, all in one SQL
 *    transaction running as the function owner.
 * 5. Redirect to /reservations. The dashboard layout will fetch the agent
 *    profile (now with role and company_id) and render normally.
 */
export async function signupCompanyAction(
  _prev: SignupState | undefined,
  formData: FormData
): Promise<SignupState | undefined> {
  const company_name = String(formData.get('company_name') ?? '').trim()
  const company_phone = String(formData.get('company_phone') ?? '').trim()
  const company_description =
    String(formData.get('company_description') ?? '').trim() || null
  const full_name = String(formData.get('full_name') ?? '').trim()
  const email = String(formData.get('email') ?? '').trim()
  const password = String(formData.get('password') ?? '')

  const fieldErrors: NonNullable<SignupState['fieldErrors']> = {}

  if (company_name.length < 2) {
    fieldErrors.company_name = 'Nom de compagnie requis (2 caractères min).'
  }
  if (company_phone.length < 6) {
    fieldErrors.company_phone = 'Téléphone invalide.'
  }
  if (full_name.length < 2) {
    fieldErrors.full_name = 'Votre nom complet est requis.'
  }
  if (!email.includes('@') || !email.includes('.')) {
    fieldErrors.email = 'Email invalide.'
  }
  if (password.length < 6) {
    fieldErrors.password = 'Mot de passe trop court (6 caractères min).'
  }

  if (Object.keys(fieldErrors).length > 0) {
    return { fieldErrors }
  }

  const supabase = await createClient()

  // ── 1. Sign up the admin user ─────────────────────────────────────────
  const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { full_name } },
  })

  if (signUpError) {
    return { error: frenchAuthError(signUpError.message) }
  }

  // ── 2. Ensure we actually have a session ──────────────────────────────
  if (!signUpData.session) {
    // Email confirmation is on — try to sign in immediately. In dev with
    // confirmation off this also succeeds and gives us the session.
    const { error: signInError } = await supabase.auth.signInWithPassword({
      email,
      password,
    })
    if (signInError) {
      // Confirmation really is required — surface a clear message and stop.
      return {
        error:
          'Compte créé. Confirmez votre email avant de pouvoir poursuivre.',
      }
    }
  }

  // ── 3. Create the company and link the new user via RPC ───────────────
  const { error: rpcError } = await supabase.rpc('signup_company', {
    p_name: company_name,
    p_phone: company_phone,
    p_description: company_description,
  })

  if (rpcError) {
    // The auth user already exists at this point; surfacing the raw message
    // helps the user (and Pelerain support) understand what went wrong.
    return { error: `Création de la compagnie impossible : ${rpcError.message}` }
  }

  // ── 4. Land in the dashboard ──────────────────────────────────────────
  redirect('/reservations?welcome=1')
}

function frenchAuthError(raw: string): string {
  const lower = raw.toLowerCase()
  if (lower.includes('already registered') || lower.includes('user already')) {
    return 'Un compte existe déjà avec cet email. Connectez-vous depuis /login.'
  }
  if (lower.includes('password')) return 'Mot de passe trop court.'
  if (lower.includes('email')) return 'Email invalide.'
  if (lower.includes('network')) return 'Pas de connexion internet.'
  return raw
}
