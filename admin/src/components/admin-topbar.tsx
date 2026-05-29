'use client'

import Image from 'next/image'
import { Building2, LogOut, Shield } from 'lucide-react'
import { logoutAction } from '@/app/login/actions'
import type { AgentProfile } from '@/lib/auth'
import { NavLink } from './nav-link'

/**
 * Topbar variant for the Pelerain super-admin. The brand mark is the same
 * but tagged with a small "Console Pelerain" subtitle so the admin can
 * tell at a glance they're outside the regular company back-office.
 */
export function AdminTopbar({ admin }: { admin: AgentProfile }) {
  return (
    <header className="sticky top-0 z-30 border-b border-border-light bg-content/95 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-between gap-4 px-6">
        {/* Brand */}
        <div className="flex items-center gap-3">
          <Image
            src="/pelerain-logo.png"
            alt="Pelerain"
            width={120}
            height={32}
            priority
            className="h-8 w-auto object-contain brightness-0 invert"
          />
          <span className="hidden items-center gap-1.5 rounded-full bg-white/10 px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider text-white sm:inline-flex">
            <Shield className="h-3 w-3" />
            Console
          </span>
        </div>

        {/* Nav */}
        <nav className="flex items-center gap-1">
          <NavLink
            href="/admin/companies"
            label="Compagnies"
            icon={Building2}
            variant="dark"
          />
        </nav>

        {/* Right cluster */}
        <div className="flex items-center gap-3">
          <div className="hidden text-right sm:block">
            <p className="text-sm font-semibold leading-tight text-white">
              {admin.full_name}
            </p>
            <p className="text-xs leading-tight text-white/60">
              Super-admin
            </p>
          </div>
          <form action={logoutAction}>
            <button
              type="submit"
              title="Se déconnecter"
              className="grid h-9 w-9 place-items-center rounded-full border border-white/20 bg-white/5 text-white/80 transition hover:border-white/40 hover:bg-white/10 hover:text-white"
            >
              <LogOut className="h-4 w-4" />
            </button>
          </form>
        </div>
      </div>
    </header>
  )
}
