import { Outlet, Link, useLocation, useNavigate } from 'react-router'
import { ShoppingCart, ArrowLeft, LogOut, UserCircle } from 'lucide-react'
import { useCartStore } from '@/store/cartStore'
import ProtectedRoute from '@/features/auth/ProtectedRoute'
import { useAuthStore } from '@/store/authStore'

export default function CustomerLayout() {
  const items = useCartStore((state) => state.items)
  const totalItems = items.reduce((sum, i) => sum + i.quantity, 0)
  const location = useLocation()
  const isHome = location.pathname === '/'
  const isCart = location.pathname === '/carrito'
  const clearAuth = useAuthStore((state) => state.clearAuth)
  const navigate = useNavigate()

  function handleLogout() {
    clearAuth()
    navigate('/login', { replace: true })
  }

  return (
    <ProtectedRoute allowedRoles={['customer', 'admin']}>
      <div className="min-h-dvh bg-(--color-background)">
        <header className="sticky top-0 z-40 bg-(--color-background)/95 backdrop-blur border-b border-(--color-border) px-4 h-14 flex items-center justify-between">
          {isHome ? (
            <span className="font-bold text-(--color-text-primary) text-base">Two Brothers</span>
          ) : (
            <Link
              to={isCart ? '/' : '/'}
              className="flex items-center gap-1.5 text-(--color-text-secondary) text-sm"
            >
              <ArrowLeft size={17} />
              Menú
            </Link>
          )}

          <div className="flex items-center gap-1">
            {!isCart && (
              <Link to="/carrito" className="relative p-1">
                <ShoppingCart size={22} className="text-(--color-text-primary)" />
                {totalItems > 0 && (
                  <span className="absolute -top-0.5 -right-0.5 bg-(--color-primary) text-(--color-background) text-[10px] font-bold w-4.5 h-4.5 rounded-full flex items-center justify-center leading-none">
                    {totalItems}
                  </span>
                )}
              </Link>
            )}
            <Link
              to="/perfil"
              title="Mi perfil"
              className="p-1.5 text-(--color-text-muted) hover:text-(--color-text-primary) transition-colors"
            >
              <UserCircle size={20} />
            </Link>
            <button
              onClick={handleLogout}
              title="Cerrar sesión"
              className="p-1.5 text-(--color-text-muted) hover:text-red-400 transition-colors"
            >
              <LogOut size={18} />
            </button>
          </div>
        </header>

        <Outlet />
      </div>
    </ProtectedRoute>
  )
}
