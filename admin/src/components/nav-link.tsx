'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import type { LucideIcon } from 'lucide-react'
import { cn } from '@/lib/cn'

/**
 * Topbar nav item with active-state highlight. Has to be a client component
 * so it can read `usePathname()` to know which link is current.
 */
export function NavLink({
  href,
  label,
  icon: Icon,
}: {
  href: string
  label: string
  icon: LucideIcon
}) {
  const pathname = usePathname()
  const active = pathname === href || pathname.startsWith(`${href}/`)

  return (
    <Link
      href={href}
      className={cn(
        'inline-flex items-center gap-2 rounded-full px-3.5 py-1.5 text-sm font-semibold transition',
        active
          ? 'bg-primary/10 text-primary'
          : 'text-content-tertiary hover:bg-surface-neutral hover:text-content'
      )}
    >
      <Icon className="h-4 w-4" />
      {label}
    </Link>
  )
}
