import { useState } from 'react'
import { Navigate, useNavigate } from 'react-router'
import { useGoogleLogin } from '@react-oauth/google'
import { useAuthStore } from '@/store/authStore'
import { api } from '@/lib/api'
import type { User, UserRole } from '@/types/users'

const HOME_BY_ROLE: Record<UserRole, string> = {
  admin: '/admin',
  delivery: '/delivery',
  customer: '/',
}

export default function LoginPage() {
  const user = useAuthStore((state) => state.user)
  const setAuth = useAuthStore((state) => state.setAuth)
  const navigate = useNavigate()
  const [error, setError] = useState<'oauth_failed' | 'pending' | null>(null)
  const [loading, setLoading] = useState(false)

  const login = useGoogleLogin({
    onSuccess: async (tokenResponse) => {
      try {
        const data = await api.post<{ token: string; user: User }>('/api/v1/auth/google', {
          access_token: tokenResponse.access_token,
        })
        setAuth(data.user, data.token)
        navigate(HOME_BY_ROLE[data.user.role], { replace: true })
      } catch (e: unknown) {
        const msg = e instanceof Error ? e.message : ''
        setError(msg.includes('pendiente') ? 'pending' : 'oauth_failed')
      } finally {
        setLoading(false)
      }
    },
    onError: () => {
      setError('oauth_failed')
      setLoading(false)
    },
  })

  if (user) {
    return <Navigate to={HOME_BY_ROLE[user.role]} replace />
  }

  function handleGoogleLogin() {
    setError(null)
    setLoading(true)
    login()
  }

  return (
    <div className="min-h-dvh bg-(--color-background) flex flex-col relative overflow-hidden">
      {/* Atmospheric background */}
      <div className="absolute inset-0 z-0">
        <img
          src="https://lh3.googleusercontent.com/aida-public/AB6AXuD5qf320lP-Pd1gI_B1MVLvSatJyQ-tSAsaB8IJl4O60Z59sAn-i4fDFxfyab1IL13RLHkVLYcYI7Z19nnGzm8gvypUtYwv6Y9t2Onl1ETwIE-YFe0zEzs-ADzbeVM6bM7uUzS4_59f1h-ggk9Qc-gd9RmdievIGFk24ZK_Cw_U3ax76QC7K_fSufyjdNl-9tyr19gtWVZ6noGlsbreKRViFaw2Xl79DfTu69DlNR-Ax55tXzuJIeQWyKNcsJ_bTUTrD3rFIE07GE6u"
          alt=""
          className="w-full h-full object-cover"
          onError={(e) => {
            e.currentTarget.style.display = 'none'
          }}
        />
        <div className="absolute inset-0 culinary-noir-gradient" />
      </div>

      {/* Ambient glow */}
      <div className="absolute bottom-1/3 left-1/2 -translate-x-1/2 w-72 h-72 rounded-full amber-glow z-10 pointer-events-none" />

      {/* Brand section */}
      <div className="relative z-20 flex-grow flex flex-col justify-end items-center pb-14 px-6 text-center">
        <h1 className="text-5xl font-black tracking-tighter text-(--color-text-primary) uppercase leading-none mb-3">
          Two Brothers
        </h1>
        <p className="text-(--color-text-secondary) font-medium tracking-widest text-xs uppercase">
          Pollos al espiedo · Desde el barrio
        </p>
      </div>

      {/* Login card — bottom sheet */}
      <div className="relative z-30 bg-(--color-surface) rounded-t-[24px] px-8 pt-10 pb-12 shadow-[0_-8px_48px_rgba(0,0,0,0.5)]">
        {/* Drag indicator */}
        <div className="absolute top-3 left-1/2 -translate-x-1/2 w-12 h-1 bg-(--color-text-secondary)/10 rounded-full" />

        <div className="max-w-md mx-auto">
          <div className="mb-8">
            <h2 className="text-2xl font-semibold text-(--color-text-primary) mb-1">
              Bienvenido
            </h2>
            <p className="text-sm text-(--color-text-secondary) leading-relaxed">
              Ingresá con tu cuenta de Google para hacer tu pedido
            </p>
          </div>

          {/* Google button */}
          <button
            onClick={handleGoogleLogin}
            disabled={loading}
            className="w-full bg-white flex items-center justify-center gap-3 py-4 rounded-full transition-transform active:scale-[0.98] duration-200 disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {loading ? (
              <div className="w-5 h-5 rounded-full border-2 border-gray-300 border-t-gray-600 animate-spin" />
            ) : (
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                <path
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                  fill="#4285F4"
                />
                <path
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-1 .67-2.28 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  fill="#34A853"
                />
                <path
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z"
                  fill="#FBBC05"
                />
                <path
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                  fill="#EA4335"
                />
              </svg>
            )}
            <span className="text-[#1a1b21] font-semibold text-base">
              {loading ? 'Iniciando sesión...' : 'Continuar con Google'}
            </span>
          </button>

          {/* Error messages */}
          {error === 'pending' && (
            <div className="mt-4 bg-[#3D2E10] border border-(--color-accent)/40 rounded-(--radius-lg) p-4">
              <p className="text-sm font-semibold text-(--color-accent)">
                Cuenta pendiente de activación
              </p>
              <p className="text-xs text-(--color-accent)/70 mt-1">
                Tu cuenta fue creada. El administrador debe asignarte un rol para que puedas
                acceder.
              </p>
            </div>
          )}

          {error === 'oauth_failed' && (
            <div className="mt-4 bg-[#3D1010] border border-(--color-destructive)/40 rounded-(--radius-lg) p-4">
              <p className="text-sm font-semibold text-(--color-destructive)">
                Error al iniciar sesión
              </p>
              <p className="text-xs text-(--color-destructive)/70 mt-1">
                Ocurrió un problema con Google. Intentá de nuevo.
              </p>
            </div>
          )}

          {/* Legal footer */}
          <div className="mt-10 text-center">
            <p className="text-[12px] text-(--color-text-secondary)/50 leading-tight">
              Al ingresar aceptás nuestros{' '}
              <span className="underline cursor-pointer">términos y condiciones</span>
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
