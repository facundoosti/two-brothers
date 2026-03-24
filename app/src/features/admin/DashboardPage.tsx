import { Package, Clock, CheckCircle2, BarChart2, ArrowRight } from 'lucide-react'
import { Link } from 'react-router'
import AdminTopbar from './components/AdminTopbar'
import { ORDER_STATUS_LABEL, ORDER_STATUS_CLASSES } from '@/lib/status'
import { useDashboard, useDailyStock } from '@/api/dashboard'
import { useOrders } from '@/api/orders'
import { useDeliveryAssignments } from '@/api/deliveryAssignments'
import { useOrderStatus } from '@/hooks/useOrderStatus'
import type { OrderModality, OrderStatus } from '@/types/orders'

function ModalityBadge({ modality }: { modality: OrderModality }) {
  return (
    <span className={`badge ${modality === 'delivery' ? 'bg-(--color-primary)/15 text-(--color-primary)' : 'bg-(--color-accent)/15 text-(--color-accent)'}`}>
      {modality === 'delivery' ? 'Delivery' : 'Retiro'}
    </span>
  )
}

function StatusBadge({ status }: { status: OrderStatus }) {
  return (
    <span className={`badge ${ORDER_STATUS_CLASSES[status]}`}>
      {ORDER_STATUS_LABEL[status]}
    </span>
  )
}

export default function DashboardPage() {
  useOrderStatus()
  const { data: stats } = useDashboard()
  const { data: stock } = useDailyStock()
  const { data: ordersData } = useOrders()
  const { data: assignmentsData } = useDeliveryAssignments()

  const now = new Date()
  const subtitle = `${now.toLocaleDateString('es-AR', { weekday: 'long', day: 'numeric', month: 'long' })} · ${now.toLocaleTimeString('es-AR', { hour: '2-digit', minute: '2-digit' })} hs`

  const activeStatuses: OrderStatus[] = ['confirmed', 'preparing', 'ready', 'delivering']
  const activeOrders = (ordersData?.data ?? []).filter(o => activeStatuses.includes(o.status))

  const activeAssignments = (assignmentsData?.data ?? []).filter(
    a => a.status === 'in_transit' || a.status === 'assigned'
  )

  const STATS = [
    {
      label: 'Órdenes del día',
      value: stats?.orders_today ?? '—',
      icon: Package,
      color: 'text-(--color-text-primary)',
    },
    {
      label: 'En curso',
      value: Object.entries(stats?.orders_by_status ?? {})
        .filter(([s]) => activeStatuses.includes(s as OrderStatus))
        .reduce((acc, [, n]) => acc + n, 0) || '—',
      icon: Clock,
      color: 'text-(--color-accent)',
    },
    {
      label: 'Completadas',
      value: stats?.orders_by_status?.delivered ?? '—',
      icon: CheckCircle2,
      color: 'text-(--color-primary)',
    },
    {
      label: 'Stock disponible',
      value: stock
        ? `${stock.reduce((s, i) => s + i.available, 0)}/${stock.reduce((s, i) => s + i.total, 0)}`
        : '—',
      icon: BarChart2,
      color: 'text-(--color-primary)',
      large: true,
    },
  ]

  return (
    <>
      <AdminTopbar title="Dashboard" subtitle={subtitle} />

      <div className="flex-1 p-8 flex flex-col gap-6 overflow-y-auto">
        {/* Stat cards */}
        <div className="grid grid-cols-4 gap-4">
          {STATS.map((s) => (
            <div key={s.label} className="bg-(--color-surface) rounded-xl p-5 border border-(--color-border) flex flex-col gap-2">
              <div className="flex items-center justify-between">
                <p className="text-xs text-(--color-text-secondary)">{s.label}</p>
                <s.icon size={16} className="text-(--color-text-muted)" />
              </div>
              <p className={`font-bold ${s.large ? 'text-3xl' : 'text-4xl'} ${s.color}`}>{s.value}</p>
            </div>
          ))}
        </div>

        {/* Active orders */}
        <div className="bg-(--color-surface) rounded-xl border border-(--color-border)">
          <div className="flex items-center justify-between px-6 py-4 border-b border-(--color-border)">
            <h2 className="font-semibold text-(--color-text-primary)">Órdenes activas</h2>
            <Link to="/admin/ordenes" className="text-xs text-(--color-primary) hover:underline flex items-center gap-1">
              Ver todas <ArrowRight size={12} />
            </Link>
          </div>
          <div className="overflow-x-auto">
            {activeOrders.length === 0 ? (
              <p className="px-6 py-8 text-sm text-(--color-text-muted) text-center">No hay órdenes activas</p>
            ) : (
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-(--color-border)">
                    {['# Orden', 'Cliente', 'Modalidad', 'Ítems', 'Total', 'Estado', ''].map((h) => (
                      <th key={h} className="px-6 py-3 text-left text-xs text-(--color-text-muted) font-medium whitespace-nowrap">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {activeOrders.map((order) => (
                    <tr key={order.id} className="border-b border-(--color-border) last:border-0 hover:bg-(--color-surface-elevated) transition-colors">
                      <td className="px-6 py-3.5 font-mono text-xs text-(--color-text-primary) font-medium">#{String(order.id).padStart(4, '0')}</td>
                      <td className="px-6 py-3.5 text-(--color-text-primary)">{order.user.name}</td>
                      <td className="px-6 py-3.5"><ModalityBadge modality={order.modality} /></td>
                      <td className="px-6 py-3.5 text-(--color-text-secondary)">{order.order_items.reduce((s, i) => s + i.quantity, 0)}</td>
                      <td className="px-6 py-3.5 text-(--color-text-primary) font-medium">${Number(order.total).toLocaleString('es-AR')}</td>
                      <td className="px-6 py-3.5"><StatusBadge status={order.status} /></td>
                      <td className="px-6 py-3.5">
                        <Link to={`/admin/ordenes/${order.id}`} className="text-xs text-(--color-primary) hover:underline">
                          Ver →
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* Delivery people */}
        <div className="bg-(--color-surface) rounded-xl border border-(--color-border)">
          <div className="flex items-center justify-between px-6 py-4 border-b border-(--color-border)">
            <div className="flex items-center gap-3">
              <h2 className="font-semibold text-(--color-text-primary)">Repartidores</h2>
              <span className="badge bg-(--color-primary)/15 text-(--color-primary)">
                {activeAssignments.filter(a => a.status === 'in_transit').length} en reparto
              </span>
            </div>
            <Link to="/admin/repartidores" className="text-xs text-(--color-primary) hover:underline flex items-center gap-1">
              Ver todos <ArrowRight size={12} />
            </Link>
          </div>
          <div className="divide-y divide-(--color-border)">
            {activeAssignments.length === 0 ? (
              <p className="px-6 py-8 text-sm text-(--color-text-muted) text-center">Sin repartidores activos</p>
            ) : (
              activeAssignments.map((a) => (
                <div key={a.id} className="flex items-center justify-between px-6 py-3.5">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-(--color-surface-elevated) border border-(--color-border) flex items-center justify-center text-xs font-semibold text-(--color-text-secondary)">
                      {a.user_name.split(' ').map(n => n[0]).join('').slice(0, 2)}
                    </div>
                    <div>
                      <p className="text-sm font-medium text-(--color-text-primary)">{a.user_name}</p>
                      {a.order.delivery_address && (
                        <p className="text-xs text-(--color-text-secondary)">
                          Orden #{String(a.order.id).padStart(4, '0')} · {a.order.delivery_address}
                        </p>
                      )}
                    </div>
                  </div>
                  <span className={`badge ${a.status === 'in_transit' ? 'bg-(--color-accent)/15 text-(--color-accent)' : 'bg-(--color-primary)/15 text-(--color-primary)'}`}>
                    {a.status === 'in_transit' ? 'En reparto' : 'Disponible'}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </>
  )
}
