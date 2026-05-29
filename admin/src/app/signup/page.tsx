import Image from 'next/image'
import Link from 'next/link'
import { SignupForm } from './signup-form'

export default function SignupPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-background px-4 py-12">
      <div className="w-full max-w-lg">
        {/* Brand header */}
        <div className="mb-8 flex flex-col items-center text-center">
          <Image
            src="/pelerain-logo.png"
            alt="Pelerain"
            width={200}
            height={72}
            priority
            className="mb-5 h-16 w-auto object-contain"
          />
          <h1 className="text-2xl font-black tracking-tight text-content">
            Inscrivez votre compagnie
          </h1>
          <p className="mt-1.5 text-sm text-content-tertiary">
            Rejoignez Pelerain et commencez à recevoir des réservations en
            ligne dès aujourd'hui.
          </p>
        </div>

        <div className="rounded-3xl border border-border-light bg-surface p-7 shadow-xl shadow-content/5">
          <SignupForm />
        </div>

        <p className="mt-6 text-center text-sm text-content-tertiary">
          Vous avez déjà un compte ?{' '}
          <Link
            href="/login"
            className="font-bold text-primary transition hover:text-primary-dark"
          >
            Se connecter
          </Link>
        </p>
      </div>
    </main>
  )
}
