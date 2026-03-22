import { useState } from 'react'
import { Search, UserCog } from 'lucide-react'
import AdminTopbar from './components/AdminTopbar'
import { cn } from '@/lib/utils'
import { useUsers, useUpdateUser } from '@/api/users'
import type { UserRole, UserStatus } from '@/types/users'

const ROLE_LABEL: Record<UserRole, string> = {
  admin: 'Admin',
  delivery: 'Repartidor',
  customer: 'Cliente',
}

const ROLE_CLASSES: Record<UserRole, string> = {
  admin:    'bg-[#1A2234] text-(--color-primary) border border-(--color-primary)/30',
  delivery: 'bg-[#1A1E2E] text-(--color-status-confirmed) border border-(--color-status-confirmed)/30',
  customer: 'bg-(--color-surface-elevated) text-(--color-text-secondary) border border-(--color-border)',
}

export default function UsersPage() {
  const [search, setSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState<UserRole | 'all'>('all')
  const [editingId, setEditingId] = useState<number | null>(null)

  const { data, isLoading } = useUsers({
    role: roleFilter === 'all' ? undefined : roleFilter,
    q: search || undefined,
  })
  const updateUser = useUpdateUser()

  const users = data?.data ?? []

  const STATS = [
    { label: 'Total usuarios',    value: data?.pagy.count ?? '—' },
    { label: 'Clientes activos',  value: users.filter(u => u.role === 'customer' && u.status === 'active').length, green: true },
    { label: 'Repartidores',      value: users.filter(u => u.role === 'delivery').length },
    { label: 'Pendientes',        value: users.filter(u => u.status === 'pending').length, warn: true },
  ]

  function changeRole(id: number, role: UserRole) {
    updateUser.mutate({ id, role }, { onSuccess: () => setEditingId(null) })
  }

  function activateUser(id: number) {
    updateUser.mutate({ id, status: 'active' as UserStatus })
  }

  return (
    <>
      <AdminTopbar title="Usuarios" subtitle="Gestión de roles y accesos" />

      <div className="flex-1 p-8 flex flex-col gap-6 overflow-y-auto">
        {/* Stats */}
        <div className="grid grid-cols-4 gap-4">
          {STATS.map((s) => (
            <div key={s.label} className="card p-5">
              <p className="text-xs text-(--color-text-secondary) mb-2">{s.label}</p>
              <p className={cn('text-4xl font-bold', s.green ? 'text-(--color-primary)' : s.warn ? 'text-(--color-accent)' : 'text-(--color-text-primary)')}>
                {s.value}
              </p>
            </div>
          ))}
        </div>

        {/* Filters */}
        <div className="flex items-center gap-3">
          <div className="relative flex-1 max-w-xs">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-(--color-text-muted)" />
            <input
              type="text"
              placeholder="Buscar por nombre o email..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="form-input w-full pl-8"
            />
          </div>
          <div className="flex items-center gap-1.5">
            {(['all', 'admin', 'delivery', 'customer'] as const).map((r) => (
              <button
                key={r}
                onClick={() => setRoleFilter(r)}
                className={cn(
                  'px-3 py-1.5 rounded-lg text-xs font-medium transition-colors',
                  roleFilter === r
                    ? 'bg-(--color-primary) text-black'
                    : 'bg-(--color-surface) text-(--color-text-secondary) hover:text-(--color-text-primary) border border-(--color-border)',
                )}
              >
                {r === 'all' ? 'Todos' : ROLE_LABEL[r]}
              </button>
            ))}
          </div>
        </div>

        {/* Table */}
        <div className="card overflow-hidden">
          {isLoading ? (
            <p className="py-16 text-center text-sm text-(--color-text-muted)">Cargando usuarios...</p>
          ) : (
            <table className="w-full">
              <thead>
                <tr className="border-b border-(--color-border)">
                  {['Usuario', 'Email', 'Rol', 'Estado', 'Alta', ''].map((h) => (
                    <th key={h} className="table-th uppercase tracking-wider">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-(--color-border)">
                {users.map((user) => (
                  <tr key={user.id} className="hover:bg-(--color-surface-elevated)/40 transition-colors">
                    <td className="table-td">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-(--color-surface-elevated) border border-(--color-border) flex items-center justify-center text-xs font-semibold text-(--color-text-secondary) shrink-0">
                          {user.name.split(' ').map((n) => n[0]).join('').slice(0, 2)}
                        </div>
                        <span className="text-sm font-medium text-(--color-text-primary)">{user.name}</span>
                      </div>
                    </td>
                    <td className="table-td">
                      <span className="text-sm text-(--color-text-secondary)">{user.email}</span>
                    </td>
                    <td className="table-td">
                      {editingId === user.id ? (
                        <RoleSelector
                          current={user.role}
                          onSelect={(role) => changeRole(user.id, role)}
                          onCancel={() => setEditingId(null)}
                        />
                      ) : (
                        <span className={cn('text-xs px-2 py-0.5 rounded-full font-medium', ROLE_CLASSES[user.role])}>
                          {ROLE_LABEL[user.role]}
                        </span>
                      )}
                    </td>
                    <td className="table-td">
                      {user.status === 'pending' ? (
                        <span className="text-xs px-2 py-0.5 rounded-full font-medium bg-[#3D2E10] text-(--color-accent) border border-(--color-accent)/30">
                          Pendiente
                        </span>
                      ) : (
                        <span className="text-xs px-2 py-0.5 rounded-full font-medium bg-[#0D2318] text-(--color-primary) border border-(--color-primary)/30">
                          Activo
                        </span>
                      )}
                    </td>
                    <td className="table-td">
                      <span className="text-sm text-(--color-text-muted)">
                        {new Date(user.created_at).toLocaleDateString('es-AR', { day: '2-digit', month: 'short', year: 'numeric' })}
                      </span>
                    </td>
                    <td className="table-td">
                      <div className="flex items-center gap-2 justify-end">
                        {user.status === 'pending' && (
                          <button
                            onClick={() => activateUser(user.id)}
                            className="text-xs px-2.5 py-1 rounded-lg bg-(--color-primary)/15 text-(--color-primary) border border-(--color-primary)/30 hover:bg-(--color-primary)/25 transition-colors"
                          >
                            Activar
                          </button>
                        )}
                        {user.role !== 'admin' && editingId !== user.id && (
                          <button
                            onClick={() => setEditingId(user.id)}
                            className="flex items-center gap-1 text-xs px-2.5 py-1 rounded-lg text-(--color-text-secondary) hover:text-(--color-text-primary) border border-(--color-border) hover:border-(--color-primary)/40 transition-colors"
                          >
                            <UserCog size={12} />
                            Rol
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          {!isLoading && users.length === 0 && (
            <div className="py-16 text-center text-(--color-text-muted) text-sm">
              No se encontraron usuarios
            </div>
          )}
        </div>
      </div>
    </>
  )
}

function RoleSelector({
  current,
  onSelect,
  onCancel,
}: {
  current: UserRole
  onSelect: (role: UserRole) => void
  onCancel: () => void
}) {
  const ROLE_CLASSES_LOCAL: Record<UserRole, string> = {
    admin:    'bg-[#1A2234] text-(--color-primary) border border-(--color-primary)/30',
    delivery: 'bg-[#1A1E2E] text-(--color-status-confirmed) border border-(--color-status-confirmed)/30',
    customer: 'bg-(--color-surface-elevated) text-(--color-text-secondary) border border-(--color-border)',
  }
  return (
    <div className="flex items-center gap-1.5">
      {(['customer', 'delivery'] as UserRole[]).map((r) => (
        <button
          key={r}
          onClick={() => onSelect(r)}
          className={cn(
            'text-xs px-2 py-0.5 rounded-full font-medium transition-colors',
            r === current
              ? ROLE_CLASSES_LOCAL[r]
              : 'bg-(--color-surface-elevated) text-(--color-text-muted) border border-(--color-border) hover:border-(--color-primary)/40',
          )}
        >
          {ROLE_LABEL[r]}
        </button>
      ))}
      <button onClick={onCancel} className="text-xs text-(--color-text-muted) hover:text-(--color-text-primary) px-1">
        ✕
      </button>
    </div>
  )
}
