import { Outlet, NavLink, useNavigate } from 'react-router'
import { ClipboardList, Navigation, LogOut } from 'lucide-react'
import { cn } from '@/lib/utils'
import ProtectedRoute from '@/features/auth/ProtectedRoute'
import { useAuthStore } from '@/store/authStore'

export default function DeliveryLayout() {
  const user = useAuthStore((state) => state.user)
  const clearAuth = useAuthStore((state) => state.clearAuth)
  const navigate = useNavigate()

  function handleLogout() {
    clearAuth()
    navigate('/login', { replace: true })
  }

  return (
    <ProtectedRoute allowedRoles={['delivery']}>
    <div className="min-h-dvh bg-(--color-background) flex flex-col">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-(--color-surface) border-b border-(--color-border) px-4 h-14 flex items-center justify-between shrink-0">
        <div className="flex items-center gap-2.5">
          <div className="w-7 h-7 rounded-full bg-(--color-primary) flex items-center justify-center text-sm">
            🍗
          </div>
          <span className="font-semibold text-(--color-text-primary) text-sm">Two Brothers</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-(--color-surface-elevated) border border-(--color-border) flex items-center justify-center text-xs font-bold text-(--color-text-primary)">
            {user?.name.split(' ').map((n) => n[0]).join('').slice(0, 2) ?? '?'}
          </div>
          <div className="text-right">
            <p className="text-xs font-medium text-(--color-text-primary) leading-none">
              {user?.name.split(' ')[0]} {user?.name.split(' ')[1]?.[0]}.
            </p>
            <p className="text-[10px] text-(--color-primary) mt-0.5">Disponible</p>
          </div>
          <button
            onClick={handleLogout}
            title="Cerrar sesión"
            className="ml-1 flex items-center justify-center w-7 h-7 rounded-lg text-(--color-text-muted) hover:text-red-400 hover:bg-red-400/10 transition-colors"
          >
            <LogOut size={14} />
          </button>
        </div>
      </header>

      {/* Page content */}
      <div className="flex-1 pb-16">
        <Outlet />
      </div>

      {/* Bottom nav */}
      <nav className="fixed bottom-0 left-0 right-0 z-40 bg-(--color-surface) border-t border-(--color-border) flex">
        {[
          { to: '/delivery', label: 'Mis repartos', icon: ClipboardList, end: true },
          { to: '/delivery/actual', label: 'En curso', icon: Navigation, end: false },
        ].map(({ to, label, icon: Icon, end }) => (
          <NavLink
            key={to}
            to={to}
            end={end}
            className={({ isActive }) =>
              cn(
                'flex-1 flex flex-col items-center justify-center gap-1 py-2.5 text-[10px] font-medium transition-colors',
                isActive ? 'text-(--color-primary)' : 'text-(--color-text-muted)',
              )
            }
          >
            {({ isActive }) => (
              <>
                <Icon size={20} strokeWidth={isActive ? 2.5 : 1.8} />
                {label}
              </>
            )}
          </NavLink>
        ))}
      </nav>
    </div>
    </ProtectedRoute>
  )
}
