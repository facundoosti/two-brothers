import { Outlet, Link, useLocation, useNavigate } from 'react-router'
import { Utensils, ShoppingBag, User, ArrowLeft } from 'lucide-react'
import { useCartStore } from '@/store/cartStore'
import ProtectedRoute from '@/features/auth/ProtectedRoute'
import { useAuthStore } from '@/store/authStore'
import { cn } from '@/lib/utils'

export default function CustomerLayout() {
  const items = useCartStore((state) => state.items)
  const totalItems = items.reduce((sum, i) => sum + i.quantity, 0)
  const location = useLocation()
  const user = useAuthStore((state) => state.user)
  const navigate = useNavigate()

  const isCart = location.pathname === '/carrito'

  const navTabs = [
    {
      label: 'Menú',
      icon: Utensils,
      path: '/',
      active: location.pathname === '/',
    },
    {
      label: 'Carrito',
      icon: ShoppingBag,
      path: '/carrito',
      active: location.pathname === '/carrito',
      badge: totalItems > 0 ? totalItems : undefined,
    },
    {
      label: 'Perfil',
      icon: User,
      path: '/perfil',
      active: ['/perfil', '/historial'].includes(location.pathname),
    },
  ]

  return (
    <ProtectedRoute allowedRoles={['customer', 'admin']}>
      <div className="min-h-dvh bg-(--color-background)">
        {/* Header */}
        <header className="sticky top-0 z-40 bg-(--color-background)/70 backdrop-blur-xl flex items-center justify-between px-6 h-14 shadow-[0_1px_0_rgba(61,74,64,0.35)]">
          {isCart ? (
            <>
              <button
                onClick={() => navigate(-1)}
                className="text-(--color-primary) transition-transform active:scale-90"
              >
                <ArrowLeft size={22} />
              </button>
              <h1 className="flex-1 text-center font-semibold text-(--color-text-primary) text-lg">
                Tu Carrito
              </h1>
              {totalItems > 0 ? (
                <span className="bg-(--color-primary)/20 text-(--color-primary) text-[10px] font-bold px-2 py-0.5 rounded-full font-mono">
                  {totalItems}
                </span>
              ) : (
                <div className="w-8" />
              )}
            </>
          ) : (
            <>
              <h1 className="text-xl font-black tracking-widest text-(--color-text-primary) uppercase font-sans">
                TWO BROTHERS
              </h1>
              <Link to="/perfil" className="shrink-0">
                {user?.avatar_url ? (
                  <img
                    src={user.avatar_url}
                    alt={user.name}
                    className="w-9 h-9 rounded-full object-cover border-2 border-(--color-primary)"
                  />
                ) : (
                  <div className="w-9 h-9 rounded-full bg-(--color-surface-elevated) flex items-center justify-center border border-(--color-border)">
                    <User size={16} className="text-(--color-text-secondary)" />
                  </div>
                )}
              </Link>
            </>
          )}
        </header>

        {/* Page content */}
        <Outlet />

        {/* Bottom Navigation */}
        <nav className="fixed bottom-0 left-0 w-full flex justify-around items-center px-4 pb-8 pt-3 bg-(--color-background)/75 backdrop-blur-xl rounded-t-[28px] z-40 shadow-[0_-10px_40px_rgba(0,0,0,0.5)]">
          {navTabs.map(({ label, icon: Icon, path, active, badge }) => (
            <Link
              key={path}
              to={path}
              className={cn(
                'flex flex-col items-center justify-center px-5 py-2 rounded-full transition-all duration-300',
                active
                  ? 'bg-[linear-gradient(135deg,#61e698,#40c97f)] text-[#00391d] scale-105'
                  : 'text-(--color-text-secondary)',
              )}
            >
              <div className="relative mb-0.5">
                <Icon size={20} />
                {badge !== undefined && !active && (
                  <span className="absolute -top-1 -right-2 bg-(--color-primary) text-[#00391d] text-[9px] font-bold w-3.5 h-3.5 rounded-full flex items-center justify-center leading-none">
                    {badge > 9 ? '9+' : badge}
                  </span>
                )}
              </div>
              <span className="font-mono text-[10px] uppercase tracking-widest leading-none">
                {label}
              </span>
            </Link>
          ))}
        </nav>
      </div>
    </ProtectedRoute>
  )
}
