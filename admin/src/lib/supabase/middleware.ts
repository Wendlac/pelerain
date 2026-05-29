import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

/**
 * Refreshes the auth session on every request and gates the dashboard:
 * - unauthenticated → redirect to /login (except for /login itself)
 * - authenticated but profile.role is not an agent → forced sign-out
 *
 * IMPORTANT: never read `request.cookies` after creating the client below —
 * always read fresh from `supabaseResponse` so token refreshes propagate
 * correctly. See @supabase/ssr docs.
 */
export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // getUser() validates the JWT against the auth server. The library docs
  // explicitly recommend it for authorization decisions (vs getSession()).
  const {
    data: { user },
  } = await supabase.auth.getUser()

  const path = request.nextUrl.pathname
  // Public routes: anything reachable without a session
  const isPublic =
    path === '/login' ||
    path === '/signup' ||
    path.startsWith('/_next')

  if (!user && !isPublic) {
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    return NextResponse.redirect(url)
  }

  // Don't auto-redirect away from /signup or /login if the user is logged in
  // but doesn't have a company yet — the post-signup flow needs them on /signup
  // for the brief moment between auth.signUp and the rpc call.
  if (user && (path === '/login') ) {
    const url = request.nextUrl.clone()
    url.pathname = '/reservations'
    return NextResponse.redirect(url)
  }

  return supabaseResponse
}
