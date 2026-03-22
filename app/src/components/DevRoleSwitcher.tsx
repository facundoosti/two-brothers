import { useState, useRef, useEffect } from 'react'
import { useAuthStore } from '@/store/authStore'
import { api } from '@/lib/api'
import type { User, UserRole } from '@/types/users'

const ROLES: { value: UserRole; label: string; color: string }[] = [
  { value: 'customer', label: 'Cliente', color: 'bg-blue-500' },
  { value: 'delivery', label: 'Repartidor', color: 'bg-yellow-500' },
  { value: 'admin', label: 'Admin', color: 'bg-purple-500' },
]

const HOME_BY_ROLE: Record<UserRole, string> = {
  customer: '/',
  delivery: '/delivery',
  admin: '/admin',
}

export default function DevRoleSwitcher() {
  const user = useAuthStore((state) => state.user)
  const token = useAuthStore((state) => state.token)
  const setAuth = useAuthStore((state) => state.setAuth)
  const [loading, setLoading] = useState<UserRole | null>(null)

  const ref = useRef<HTMLDivElement>(null)
  const dragging = useRef(false)
  const offset = useRef({ x: 0, y: 0 })
  const [pos, setPos] = useState({ x: 16, y: window.innerHeight - 90 })

  useEffect(() => {
    function onMouseMove(e: MouseEvent) {
      if (!dragging.current) return
      setPos({
        x: Math.min(Math.max(0, e.clientX - offset.current.x), window.innerWidth - (ref.current?.offsetWidth ?? 0)),
        y: Math.min(Math.max(0, e.clientY - offset.current.y), window.innerHeight - (ref.current?.offsetHeight ?? 0)),
      })
    }
    function onMouseUp() {
      dragging.current = false
    }
    window.addEventListener('mousemove', onMouseMove)
    window.addEventListener('mouseup', onMouseUp)
    return () => {
      window.removeEventListener('mousemove', onMouseMove)
      window.removeEventListener('mouseup', onMouseUp)
    }
  }, [])

  function onMouseDown(e: React.MouseEvent) {
    dragging.current = true
    offset.current = {
      x: e.clientX - pos.x,
      y: e.clientY - pos.y,
    }
  }

  if (!user || !token) return null

  async function switchRole(role: UserRole) {
    if (role === user!.role || loading) return
    setLoading(role)
    try {
      const updated = await api.patch<User>('/dev/switch_role', { role })
      setAuth(updated, token!)
      window.location.href = HOME_BY_ROLE[role]
    } finally {
      setLoading(null)
    }
  }

  return (
    <div
      ref={ref}
      style={{ left: pos.x, top: pos.y }}
      className="fixed z-50 flex flex-col gap-1.5 bg-(--color-surface) border border-(--color-border) rounded-(--radius-lg) shadow-lg select-none"
    >
      {/* Handle */}
      <div
        onMouseDown={onMouseDown}
        className="flex items-center gap-2 px-3 pt-2.5 pb-1 cursor-grab active:cursor-grabbing"
      >
        <svg width="10" height="10" viewBox="0 0 10 10" className="text-(--color-text-muted) flex-shrink-0">
          <circle cx="2" cy="2" r="1" fill="currentColor" />
          <circle cx="8" cy="2" r="1" fill="currentColor" />
          <circle cx="2" cy="5" r="1" fill="currentColor" />
          <circle cx="8" cy="5" r="1" fill="currentColor" />
          <circle cx="2" cy="8" r="1" fill="currentColor" />
          <circle cx="8" cy="8" r="1" fill="currentColor" />
        </svg>
        <p className="text-[10px] font-mono text-(--color-text-muted) uppercase tracking-widest">
          Dev · <span className="text-(--color-primary)">{user.role}</span>
        </p>
      </div>

      {/* Buttons */}
      <div className="flex gap-1.5 px-3 pb-3">
        {ROLES.map(({ value, label, color }) => {
          const isActive = user.role === value
          const isLoading = loading === value
          return (
            <button
              key={value}
              onClick={() => switchRole(value)}
              disabled={isActive || !!loading}
              className={[
                'text-xs font-medium px-2.5 py-1 rounded-full transition-all',
                isActive
                  ? `${color} text-white`
                  : 'bg-(--color-surface-elevated) text-(--color-text-secondary) hover:text-(--color-text-primary)',
                !!loading && !isLoading ? 'opacity-40' : '',
              ].join(' ')}
            >
              {isLoading ? '...' : label}
            </button>
          )
        })}
      </div>
    </div>
  )
}
