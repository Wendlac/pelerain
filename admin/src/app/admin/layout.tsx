import { AdminTopbar } from '@/components/admin-topbar'
import { requireSuperAdmin } from '@/lib/auth'

/**
 * Pelerain super-admin console. Anyone reaching this group is guaranteed
 * to be `role='admin'` thanks to requireSuperAdmin — child pages can act
 * without re-checking.
 */
export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const admin = await requireSuperAdmin()

  return (
    <div className="min-h-screen bg-background">
      <AdminTopbar admin={admin} />
      <main className="mx-auto max-w-7xl px-6 py-8">{children}</main>
    </div>
  )
}
