import { Navigate } from 'react-router'
import { useAuthStore } from '@/store/authStore'
import type { UserRole } from '@/types/users'

const HOME_BY_ROLE: Record<UserRole, string> = {
  admin: '/admin',
  delivery: '/delivery',
  customer: '/',
}

interface ProtectedRouteProps {
  allowedRoles: UserRole[]
  children: React.ReactNode
}

export default function ProtectedRoute({ allowedRoles, children }: ProtectedRouteProps) {
  const user = useAuthStore((state) => state.user)

  if (!user) return <Navigate to="/login" replace />

  if (!allowedRoles.includes(user.role)) {
    return <Navigate to={HOME_BY_ROLE[user.role]} replace />
  }

  return <>{children}</>
}
