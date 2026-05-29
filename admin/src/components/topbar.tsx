'use client'

import { Bus, LogOut, MapPin, Ticket } from 'lucide-react'
import { logoutAction } from '@/app/login/actions'
import type { AgentProfile } from '@/lib/auth'
import { NavLink } from './nav-link'

/**
 * Sticky top bar.
 *
 * - Left: brand
 * - Center: nav (Réservations, Trajets)
 * - Right: agent profile + logout
 */
export function Topbar({ agent }: { agent: AgentProfile }) {
  const initials = makeInitials(agent.full_name)

  return (
    <header className="sticky top-0 z-30 border-b border-border-light bg-surface/85 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between gap-4 px-6">
        {/* Brand */}
        <div className="flex items-center gap-2">
          <div className="grid h-9 w-9 place-items-center rounded-xl bg-gradient-to-br from-[#5A0FA8] to-[#9B4FFF] text-base font-black text-white">
            P
          </div>
          <span className="hidden text-sm font-bold text-content sm:inline">
            Pelerain
          </span>
        </div>

        {/* Nav */}
        <nav className="flex items-center gap-1">
          <NavLink href="/reservations" label="Réservations" icon={Ticket} />
          <NavLink href="/trips" label="Trajets" icon={Bus} />
          <NavLink href="/cities" label="Villes" icon={MapPin} />
        </nav>

        {/* Right cluster */}
        <div className="flex items-center gap-3">
          <div className="hidden text-right sm:block">
            <p className="text-sm font-semibold leading-tight text-content">
              {agent.full_name}
            </p>
            <p className="text-xs leading-tight text-content-tertiary">
              {agent.company_name ?? 'Sans compagnie'}
            </p>
          </div>
          <div className="grid h-9 w-9 place-items-center rounded-full bg-primary-surface text-sm font-bold text-primary">
            {initials}
          </div>
          <form action={logoutAction}>
            <button
              type="submit"
              title="Se déconnecter"
              className="grid h-9 w-9 place-items-center rounded-full border border-border bg-surface text-content-tertiary transition hover:border-error/40 hover:bg-error/8 hover:text-error"
            >
              <LogOut className="h-4 w-4" />
            </button>
          </form>
        </div>
      </div>
    </header>
  )
}

function makeInitials(name: string): string {
  const parts = name.trim().split(/\s+/)
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase()
  return name.slice(0, 2).toUpperCase()
}
