import { redirect } from 'next/navigation'

/**
 * Root path — the middleware will already have redirected unauthenticated
 * users to /login. For authenticated users we land them on the only screen
 * the MVP exposes: the pending reservations list.
 */
export default function Home() {
  redirect('/reservations')
}
