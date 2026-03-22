import { useEffect, useRef } from 'react'
import { useNavigate } from 'react-router'
import { useAuthStore } from '@/store/authStore'
import { api } from '@/lib/api'
import type { User } from '@/types/users'
import type { UserRole } from '@/types/users'

const HOME_BY_ROLE: Record<UserRole, string> = {
  admin: '/admin',
  delivery: '/delivery',
  customer: '/',
}

export default function AuthCallbackPage() {
  const navigate = useNavigate()
  const setAuth = useAuthStore((state) => state.setAuth)
  const called = useRef(false)

  useEffect(() => {
    if (called.current) return
    called.current = true

    const params = new URLSearchParams(window.location.search)
    const token = params.get('token')
    const error = params.get('error')

    if (error === 'pending') {
      navigate('/login?error=pending', { replace: true })
      return
    }

    if (error || !token) {
      navigate('/login?error=oauth_failed', { replace: true })
      return
    }

    // Temporarily set token so api.get can use it
    useAuthStore.setState({ token })

    api
      .get<User>('/api/v1/me')
      .then((user) => {
        setAuth(user, token)
        navigate(HOME_BY_ROLE[user.role], { replace: true })
      })
      .catch(() => {
        useAuthStore.setState({ token: null })
        navigate('/login?error=oauth_failed', { replace: true })
      })
  }, [navigate, setAuth])

  return (
    <div className="min-h-dvh bg-(--color-background) flex items-center justify-center">
      <div className="flex flex-col items-center gap-4">
        <div className="w-8 h-8 rounded-full border-2 border-(--color-text-muted) border-t-(--color-primary) animate-spin" />
        <p className="text-sm text-(--color-text-secondary)">Iniciando sesión...</p>
      </div>
    </div>
  )
}
