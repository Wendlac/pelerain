import { redirect } from 'next/navigation'

/**
 * /admin is just an alias for /admin/companies (the only console page for now).
 * The dashboard layout has already checked role=admin by the time we reach
 * this redirect.
 */
export default function AdminHome() {
  redirect('/admin/companies')
}
