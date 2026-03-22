import { NavLink, useNavigate } from 'react-router'
import {
  LayoutDashboard,
  ClipboardList,
  Users,
  UserCog,
  UtensilsCrossed,
  BarChart3,
  ChefHat,
  LogOut,
  Settings,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { useAuthStore } from '@/store/authStore'

const NAV_SECTIONS = [
  {
    title: 'Gestión',
    items: [
      { label: 'Dashboard', to: '/admin', icon: LayoutDashboard, end: true },
      { label: 'Órdenes', to: '/admin/ordenes', icon: ClipboardList },
      { label: 'Repartidores', to: '/admin/repartidores', icon: Users },
    ],
  },
  {
    title: 'Configuración',
    items: [
      { label: 'Usuarios', to: '/admin/usuarios', icon: UserCog },
      { label: 'Menú', to: '/admin/menu', icon: UtensilsCrossed },
      { label: 'Configuración', to: '/admin/configuracion', icon: Settings },
      { label: 'Reportes', to: '/admin/reportes', icon: BarChart3 },
    ],
  },
]

export default function AdminSidebar() {
  const user = useAuthStore((state) => state.user)
  const clearAuth = useAuthStore((state) => state.clearAuth)
  const navigate = useNavigate()

  function handleLogout() {
    clearAuth()
    navigate('/login', { replace: true })
  }

  return (
    <aside className="flex flex-col w-[220px] shrink-0 min-h-dvh bg-(--color-sidebar) border-r border-(--color-sidebar-border)">
      {/* Logo */}
      <div className="flex items-center gap-2.5 h-[72px] px-6 border-b border-(--color-sidebar-border)">
        <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-(--color-primary)">
          <ChefHat size={16} className="text-black" />
        </div>
        <span className="font-semibold text-sm text-(--color-text-primary)">Two Brothers</span>
      </div>

      {/* Nav */}
      <nav className="flex-1 py-4 px-3 flex flex-col gap-5 overflow-y-auto">
        {NAV_SECTIONS.map((section) => (
          <div key={section.title} className="flex flex-col gap-0.5">
            <p className="px-3 py-1 text-xs font-medium text-(--color-text-muted) uppercase tracking-wider">
              {section.title}
            </p>
            {section.items.map((item) => (
              <SidebarItem key={item.to} {...item} />
            ))}
          </div>
        ))}
      </nav>

      {/* Footer */}
      <div className="px-4 py-4 border-t border-(--color-sidebar-border) flex items-center gap-2">
        <div className="flex-1 min-w-0">
          <p className="text-xs font-medium text-(--color-text-secondary) truncate">{user?.name}</p>
          <p className="text-[11px] text-(--color-text-muted) truncate">{user?.email}</p>
        </div>
        <button
          onClick={handleLogout}
          title="Cerrar sesión"
          className="shrink-0 flex items-center justify-center w-7 h-7 rounded-lg text-(--color-text-muted) hover:text-red-400 hover:bg-red-400/10 transition-colors"
        >
          <LogOut size={14} />
        </button>
      </div>
    </aside>
  )
}

function SidebarItem({
  label,
  to,
  icon: Icon,
  end,
}: {
  label: string
  to: string
  icon: React.ElementType
  end?: boolean
}) {
  return (
    <NavLink
      to={to}
      end={end}
      className={({ isActive }) =>
        cn(
          'flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors',
          isActive
            ? 'bg-[#1A2234] text-(--color-primary) font-medium'
            : 'text-(--color-text-secondary) hover:text-(--color-text-primary) hover:bg-(--color-surface)',
        )
      }
    >
      <Icon size={16} />
      {label}
    </NavLink>
  )
}
