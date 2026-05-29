import { LoginForm } from './login-form'

const ERROR_MESSAGES: Record<string, string> = {
  access_denied:
    "Votre compte n'a pas accès au back-office. Connectez-vous avec un compte agent.",
}

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>
}) {
  const { error } = await searchParams
  const initialError = error ? ERROR_MESSAGES[error] : undefined

  return (
    <main className="flex min-h-screen items-center justify-center bg-background px-4 py-12">
      <div className="w-full max-w-md">
        {/* Brand header */}
        <div className="mb-8 flex flex-col items-center text-center">
          <div className="mb-4 grid h-16 w-16 place-items-center rounded-2xl bg-gradient-to-br from-[#5A0FA8] to-[#9B4FFF] text-3xl font-black text-white shadow-lg shadow-primary/30">
            P
          </div>
          <h1 className="text-3xl font-black tracking-tight text-content">
            Pelerain · Back-office
          </h1>
          <p className="mt-1.5 text-sm text-content-tertiary">
            Espace agent des compagnies de transport
          </p>
        </div>

        {/* Card */}
        <div className="rounded-3xl border border-border-light bg-surface p-7 shadow-xl shadow-content/5">
          <LoginForm initialError={initialError} />
        </div>
      </div>
    </main>
  )
}
