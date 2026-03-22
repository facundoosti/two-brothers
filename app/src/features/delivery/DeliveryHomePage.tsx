import { Link } from 'react-router'
import { MapPin, ChevronRight, Clock, CheckCircle2, Package } from 'lucide-react'
import { cn } from '@/lib/utils'
import { useDeliveryAssignments } from '@/api/deliveryAssignments'
import type { DeliveryAssignmentWithOrder, AssignmentStatus } from '@/types/orders'

const STATUS_CONFIG: Record<AssignmentStatus, { label: string; classes: string; icon: typeof Clock }> = {
  in_transit: { label: 'En camino',  classes: 'bg-(--color-primary)/15 text-(--color-primary)',             icon: Clock },
  assigned:   { label: 'Pendiente',  classes: 'bg-(--color-accent)/15 text-(--color-accent)',               icon: Package },
  delivered:  { label: 'Entregado',  classes: 'bg-(--color-text-secondary)/15 text-(--color-text-secondary)', icon: CheckCircle2 },
}

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-AR', {
    style: 'currency', currency: 'ARS', maximumFractionDigits: 0,
  }).format(n)
}

export default function DeliveryHomePage() {
  const { data, isLoading } = useDeliveryAssignments()
  const assignments = data?.data ?? []

  const inTransit = assignments.filter(a => a.status === 'in_transit')
  const pending   = assignments.filter(a => a.status === 'assigned')
  const delivered = assignments.filter(a => a.status === 'delivered')

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[50vh]">
        <p className="text-sm text-(--color-text-muted)">Cargando repartos...</p>
      </div>
    )
  }

  return (
    <div className="px-4 pt-4 pb-4 max-w-lg mx-auto">
      {/* Stats */}
      <div className="grid grid-cols-3 gap-2 mb-5">
        {[
          { label: 'Hoy',        value: assignments.length, color: 'text-(--color-text-primary)' },
          { label: 'Pendientes', value: pending.length,     color: 'text-(--color-accent)' },
          { label: 'Entregados', value: delivered.length,   color: 'text-(--color-primary)' },
        ].map(({ label, value, color }) => (
          <div key={label} className="bg-(--color-surface) rounded-(--radius-lg) px-3 py-3 text-center">
            <p className={cn('text-2xl font-bold', color)}>{value}</p>
            <p className="text-[11px] text-(--color-text-muted) mt-0.5">{label}</p>
          </div>
        ))}
      </div>

      {inTransit.length > 0 && (
        <section className="mb-5">
          <h2 className="section-label mb-2">En curso</h2>
          {inTransit.map(a => <AssignmentCard key={a.id} assignment={a} highlighted />)}
        </section>
      )}

      {pending.length > 0 && (
        <section className="mb-5">
          <h2 className="section-label mb-2">Por hacer</h2>
          {pending.map(a => <AssignmentCard key={a.id} assignment={a} />)}
        </section>
      )}

      {delivered.length > 0 && (
        <section>
          <h2 className="section-label mb-2">Completados hoy</h2>
          {delivered.map(a => <AssignmentCard key={a.id} assignment={a} />)}
        </section>
      )}

      {assignments.length === 0 && (
        <p className="text-center text-sm text-(--color-text-muted) py-16">No tenés repartos asignados</p>
      )}
    </div>
  )
}

function AssignmentCard({
  assignment: a, highlighted = false,
}: {
  assignment: DeliveryAssignmentWithOrder
  highlighted?: boolean
}) {
  const { label, classes } = STATUS_CONFIG[a.status]
  const isActive = a.status === 'in_transit'
  const itemsSummary = a.order.order_items
    .map(i => `${i.quantity}× ${i.name}`)
    .join(', ')

  return (
    <Link
      to={isActive ? '/delivery/actual' : '#'}
      className={cn(
        'flex items-start gap-3 rounded-(--radius-lg) p-4 mb-2 border transition-colors',
        highlighted
          ? 'bg-(--color-primary-muted) border-(--color-primary)/30'
          : 'bg-(--color-surface) border-(--color-border)',
      )}
    >
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-1">
          <span className="font-mono text-sm font-semibold text-(--color-text-primary)">
            #{String(a.order.id).padStart(4, '0')}
          </span>
          <span className={`badge-sm ${classes}`}>{label}</span>
        </div>

        {a.order.delivery_address && (
          <div className="flex items-start gap-1 mb-1">
            <MapPin size={12} className="text-(--color-text-muted) shrink-0 mt-0.5" />
            <p className="text-xs text-(--color-text-secondary) leading-tight">{a.order.delivery_address}</p>
          </div>
        )}

        <p className="text-xs text-(--color-text-muted) truncate">{itemsSummary}</p>

        <div className="flex items-center gap-3 mt-2">
          <span className="text-xs text-(--color-text-muted)">
            {a.order.payment_method === 'cash' ? '💵 Efectivo' : '📲 Transferido'}
          </span>
          {a.assigned_at && (
            <>
              <span className="text-(--color-border)">·</span>
              <span className="text-xs text-(--color-text-muted)">
                {new Date(a.assigned_at).toLocaleTimeString('es-AR', { hour: '2-digit', minute: '2-digit' })} hs
              </span>
            </>
          )}
        </div>
      </div>

      <div className="flex flex-col items-end gap-1 shrink-0">
        <span className="text-sm font-bold text-(--color-text-primary)">{formatPrice(a.order.total)}</span>
        {isActive && <ChevronRight size={15} className="text-(--color-primary)" />}
      </div>
    </Link>
  )
}
