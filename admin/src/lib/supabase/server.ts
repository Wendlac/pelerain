import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

/**
 * Supabase client for use in Server Components, Server Actions and Route
 * Handlers.
 *
 * Calls `cookies()` lazily so the result is fresh per render. The `setAll`
 * implementation is wrapped in try/catch because Server Components cannot
 * mutate cookies — when the cookies need to be refreshed, the middleware
 * picks it up on the next request.
 */
export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // Called from a Server Component — cookies can only be written
            // from a Server Action or Route Handler. The middleware refreshes
            // the session, so it's safe to ignore here.
          }
        },
      },
    }
  )
}
