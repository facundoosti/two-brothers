import { MapPin } from 'lucide-react'
import { Link } from 'react-router'
import AdminTopbar from './components/AdminTopbar'
import { useUsers } from '@/api/users'
import { useDeliveryAssignments } from '@/api/deliveryAssignments'
import type { DeliveryAssignmentWithOrder } from '@/types/orders'
import type { User } from '@/types/users'

type DerivedStatus = 'delivering' | 'confirming' | 'available'

const DELIVERY_STATUS_LABEL: Record<DerivedStatus, string> = {
  delivering: 'En reparto',
  confirming: 'Confirmando',
  available:  'Disponible',
}

const DELIVERY_STATUS_CLASSES: Record<DerivedStatus, string> = {
  delivering: 'bg-(--color-accent)/15 text-(--color-accent)',
  confirming: 'bg-(--color-status-confirmed)/15 text-(--color-status-confirmed)',
  available:  'bg-(--color-primary)/15 text-(--color-primary)',
}

function deriveStatus(userId: number, assignments: DeliveryAssignmentWithOrder[]): DerivedStatus {
  const active = assignments.find(
    a => a.user_id === userId && (a.status === 'in_transit' || a.status === 'assigned')
  )
  if (!active) return 'available'
  return active.status === 'in_transit' ? 'delivering' : 'confirming'
}

function activeAssignment(userId: number, assignments: DeliveryAssignmentWithOrder[]) {
  return assignments.find(
    a => a.user_id === userId && (a.status === 'in_transit' || a.status === 'assigned')
  )
}

export default function DeliveryStaffPage() {
  const { data: usersData, isLoading: loadingUsers } = useUsers({ role: 'delivery' })
  const { data: assignmentsData } = useDeliveryAssignments()

  const users = usersData?.data ?? []
  const assignments = assignmentsData?.data ?? []

  const delivering = users.filter(u => deriveStatus(u.id, assignments) === 'delivering')
  const available  = users.filter(u => deriveStatus(u.id, assignments) === 'available')
  const confirming = users.filter(u => deriveStatus(u.id, assignments) === 'confirming')

  const STATS = [
    { label: 'Total registrados', value: users.length },
    { label: 'En reparto ahora',  value: delivering.length, highlight: true },
    { label: 'Disponibles',       value: available.length,  green: true },
    { label: 'Confirmando',       value: confirming.length },
  ]

  return (
    <>
      <AdminTopbar
        title="Repartidores"
        subtitle="Activos y disponibles al día de hoy"
      />

      <div className="flex-1 p-8 flex flex-col gap-6 overflow-y-auto">
        {/* Stats row */}
        <div className="grid grid-cols-4 gap-4">
          {STATS.map((s) => (
            <div key={s.label} className="card p-5">
              <p className="text-xs text-(--color-text-secondary) mb-2">{s.label}</p>
              <p className={`text-4xl font-bold ${s.green ? 'text-(--color-primary)' : s.highlight ? 'text-(--color-accent)' : 'text-(--color-text-primary)'}`}>
                {s.value}
              </p>
            </div>
          ))}
        </div>

        {loadingUsers ? (
          <p className="text-sm text-(--color-text-muted) text-center py-8">Cargando repartidores...</p>
        ) : (
          <div className="grid grid-cols-3 gap-5">
            <KanbanColumn title="En reparto"  color="text-(--color-accent)"             users={delivering} assignments={assignments} />
            <KanbanColumn title="Disponible"  color="text-(--color-primary)"            users={available}  assignments={assignments} />
            <KanbanColumn title="Confirmando" color="text-(--color-status-confirmed)"   users={confirming} assignments={assignments} showConfirm />
          </div>
        )}
      </div>
    </>
  )
}

function KanbanColumn({
  title, color, users, assignments, showConfirm,
}: {
  title: string
  color: string
  users: User[]
  assignments: DeliveryAssignmentWithOrder[]
  showConfirm?: boolean
}) {
  return (
    <div className="flex flex-col gap-3">
      <div className="flex items-center gap-2 px-1">
        <span className={`text-sm font-semibold ${color}`}>{title}</span>
        <span className="text-xs text-(--color-text-muted) bg-(--color-surface) px-2 py-0.5 rounded-full border border-(--color-border)">{users.length}</span>
      </div>
      <div className="flex flex-col gap-3">
        {users.length === 0 ? (
          <p className="text-xs text-(--color-text-muted) px-1">Sin repartidores</p>
        ) : (
          users.map((user) => (
            <DeliveryCard key={user.id} user={user} assignment={activeAssignment(user.id, assignments)} showConfirm={showConfirm} />
          ))
        )}
      </div>
    </div>
  )
}

function DeliveryCard({
  user, assignment, showConfirm,
}: {
  user: User
  assignment?: DeliveryAssignmentWithOrder
  showConfirm?: boolean
}) {
  const status: DerivedStatus = assignment
    ? assignment.status === 'in_transit' ? 'delivering' : 'confirming'
    : 'available'

  return (
    <div className="card p-4 flex flex-col gap-3">
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-2.5">
          <div className="w-9 h-9 rounded-full bg-(--color-surface-elevated) border border-(--color-border) flex items-center justify-center text-sm font-semibold text-(--color-text-secondary)">
            {user.name.split(' ').map(n => n[0]).join('').slice(0, 2)}
          </div>
          <div>
            <p className="text-sm font-medium text-(--color-text-primary)">{user.name}</p>
            <p className="text-xs text-(--color-text-muted)">{user.email}</p>
          </div>
        </div>
        <span className={`badge ${DELIVERY_STATUS_CLASSES[status]}`}>
          {DELIVERY_STATUS_LABEL[status]}
        </span>
      </div>

      {assignment?.order.delivery_address && (
        <div className="flex items-start gap-1.5 text-xs text-(--color-text-secondary) bg-(--color-surface-elevated) rounded-lg p-2.5">
          <MapPin size={11} className="shrink-0 mt-0.5 text-(--color-text-muted)" />
          <div>
            <p className="font-medium text-(--color-text-primary)">Orden #{String(assignment.order.id).padStart(4, '0')}</p>
            <p>{assignment.order.delivery_address}</p>
          </div>
        </div>
      )}

      {status === 'delivering' && assignment && (
        <Link
          to={`/admin/trackeo/${assignment.id}`}
          className="w-full flex items-center justify-center gap-1.5 py-2 rounded-lg border border-(--color-border) text-xs font-medium text-(--color-text-secondary) hover:text-(--color-text-primary) hover:border-(--color-primary)/50 transition-colors"
        >
          <MapPin size={12} /> Ver en mapa
        </Link>
      )}

      {showConfirm && status === 'confirming' && (
        <div className="text-xs text-(--color-text-muted) bg-(--color-surface-elevated) rounded-lg p-2.5">
          Orden #{String(assignment?.order.id).padStart(4, '0')} pendiente de confirmación
        </div>
      )}
    </div>
  )
}
