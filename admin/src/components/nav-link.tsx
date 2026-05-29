'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import type { LucideIcon } from 'lucide-react'
import { cn } from '@/lib/cn'

/**
 * Topbar nav item with active-state highlight. Has to be a client component
 * so it can read `usePathname()` to know which link is current.
 *
 * `variant` switches the colour palette:
 * - `light` (default) → for the company topbar on a white background
 * - `dark`            → for the Pelerain admin console (dark topbar)
 */
export function NavLink({
  href,
  label,
  icon: Icon,
  variant = 'light',
}: {
  href: string
  label: string
  icon: LucideIcon
  variant?: 'light' | 'dark'
}) {
  const pathname = usePathname()
  const active = pathname === href || pathname.startsWith(`${href}/`)

  const styles =
    variant === 'dark'
      ? cn(
          'inline-flex items-center gap-2 rounded-full px-3.5 py-1.5 text-sm font-semibold transition',
          active
            ? 'bg-white/15 text-white'
            : 'text-white/70 hover:bg-white/10 hover:text-white'
        )
      : cn(
          'inline-flex items-center gap-2 rounded-full px-3.5 py-1.5 text-sm font-semibold transition',
          active
            ? 'bg-primary/10 text-primary'
            : 'text-content-tertiary hover:bg-surface-neutral hover:text-content'
        )

  return (
    <Link href={href} className={styles}>
      <Icon className="h-4 w-4" />
      {label}
    </Link>
  )
}
