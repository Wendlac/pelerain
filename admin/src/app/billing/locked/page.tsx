import Image from 'next/image'
import { Lock, MessageCircle, Mail } from 'lucide-react'
import { logoutAction } from '@/app/login/actions'
import { requireAgentEvenIfLocked } from '@/lib/auth'

/**
 * Lockout page shown when:
 * - the agent has no company linked (`no_company`)
 * - their company's subscription is suspended / expired / past_due
 *
 * We deliberately keep this page outside the (dashboard) route group so the
 * locked agent doesn't render the topbar nav (otherwise they could click
 * around even though every page would redirect them right back here).
 */
const REASON_MESSAGES: Record<string, { title: string; body: string }> = {
  no_company: {
    title: "Aucune compagnie associée",
    body:
      "Votre compte n'est rattaché à aucune compagnie de transport. Contactez l'équipe Pelerain pour finaliser votre rattachement.",
  },
  suspended: {
    title: 'Abonnement suspendu',
    body:
      "L'accès au back-office de votre compagnie est actuellement suspendu. Régularisez votre abonnement pour retrouver vos réservations et vos trajets.",
  },
  trial_expired: {
    title: "Période d'essai terminée",
    body:
      "Votre essai gratuit est arrivé à échéance. Activez un abonnement Pelerain pour continuer à recevoir des réservations.",
  },
  period_expired: {
    title: 'Abonnement expiré',
    body:
      "Votre abonnement Pelerain est expiré. Renouvelez-le pour réactiver l'accès au back-office.",
  },
  past_due: {
    title: 'Paiement en retard',
    body:
      "Le dernier prélèvement n'a pas abouti. Mettez à jour votre mode de paiement pour éviter une suspension.",
  },
  unknown: {
    title: 'Accès indisponible',
    body:
      "L'accès au back-office est temporairement indisponible. Contactez l'équipe Pelerain pour en savoir plus.",
  },
}

const SUPPORT_WHATSAPP = '+22670000000' // TODO: replace with the real Pelerain support number
const SUPPORT_EMAIL = 'contact@pelerain.com'

export default async function LockedPage({
  searchParams,
}: {
  searchParams: Promise<{ reason?: string }>
}) {
  const agent = await requireAgentEvenIfLocked()
  const { reason = 'unknown' } = await searchParams
  const message = REASON_MESSAGES[reason] ?? REASON_MESSAGES.unknown

  const whatsappUrl = `https://wa.me/${SUPPORT_WHATSAPP.replace(/[^\d]/g, '')}?text=${encodeURIComponent(
    `Bonjour Pelerain, je suis ${agent.full_name} (${agent.company_name ?? 'sans compagnie'}). Je souhaite régulariser mon accès au back-office.`
  )}`

  return (
    <main className="flex min-h-screen items-center justify-center bg-background px-4 py-12">
      <div className="w-full max-w-lg">
        {/* Brand header */}
        <div className="mb-8 flex flex-col items-center text-center">
          <Image
            src="/pelerain-logo.png"
            alt="Pelerain"
            width={180}
            height={56}
            priority
            className="mb-5 h-14 w-auto object-contain"
          />
        </div>

        {/* Lock card */}
        <div className="rounded-3xl border border-border-light bg-surface p-8 shadow-xl shadow-content/5">
          <div className="mb-5 grid h-14 w-14 place-items-center rounded-2xl bg-error/10 text-error">
            <Lock className="h-7 w-7" />
          </div>

          <h1 className="text-2xl font-black tracking-tight text-content">
            {message.title}
          </h1>
          <p className="mt-2 text-sm leading-relaxed text-content-secondary">
            {message.body}
          </p>

          {/* Agent + company info */}
          <div className="mt-6 rounded-2xl border border-border-light bg-surface-neutral/50 p-4 text-sm">
            <p className="text-content-secondary">
              <span className="font-semibold text-content">Compte :</span>{' '}
              {agent.full_name}{' '}
              <span className="text-content-tertiary">({agent.email})</span>
            </p>
            <p className="text-content-secondary">
              <span className="font-semibold text-content">Compagnie :</span>{' '}
              {agent.company_name ?? <em>aucune</em>}
            </p>
            {agent.subscription_status && (
              <p className="text-content-secondary">
                <span className="font-semibold text-content">Statut :</span>{' '}
                <code className="rounded bg-surface px-1.5 py-0.5 font-mono text-xs">
                  {agent.subscription_status}
                </code>
              </p>
            )}
          </div>

          {/* Contact actions */}
          <div className="mt-6 space-y-3">
            <a
              href={whatsappUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="flex w-full items-center justify-center gap-2 rounded-full bg-success px-6 py-3.5 text-sm font-bold text-white transition hover:bg-success-dark"
            >
              <MessageCircle className="h-4 w-4" />
              Contacter Pelerain par WhatsApp
            </a>
            <a
              href={`mailto:${SUPPORT_EMAIL}?subject=${encodeURIComponent('Régularisation accès back-office')}`}
              className="flex w-full items-center justify-center gap-2 rounded-full border border-border bg-surface px-6 py-3.5 text-sm font-bold text-content transition hover:bg-surface-neutral"
            >
              <Mail className="h-4 w-4" />
              Envoyer un email
            </a>

            <form action={logoutAction}>
              <button
                type="submit"
                className="w-full rounded-full px-6 py-2.5 text-xs font-semibold text-content-tertiary transition hover:text-content"
              >
                Se déconnecter
              </button>
            </form>
          </div>
        </div>

        <p className="mt-6 text-center text-xs text-content-tertiary">
          Pelerain · Plateforme de transport interurbain
        </p>
      </div>
    </main>
  )
}
