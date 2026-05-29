import { Topbar } from '@/components/topbar'
import { requireAgent } from '@/lib/auth'

/**
 * All routes under this group require an authenticated agent.
 * `requireAgent` redirects to /login if the role check fails — so the
 * children components can assume `agent` exists on every render.
 */
export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const agent = await requireAgent()

  return (
    <div className="min-h-screen bg-background">
      <Topbar agent={agent} />
      <main className="mx-auto max-w-7xl px-6 py-8">{children}</main>
    </div>
  )
}
