import { useState } from 'react'
import { Search, Eye, ChevronLeft, ChevronRight, Plus } from 'lucide-react'
import AdminTopbar from './components/AdminTopbar'
import { ORDER_STATUS_LABEL, ORDER_STATUS_CLASSES } from '@/lib/status'
import { useOrders } from '@/api/orders'
import type { OrderStatus } from '@/types/orders'
import { useOrderStatus } from '@/hooks/useOrderStatus'
import { Link, useNavigate } from 'react-router'
import CounterOrderModal from './components/CounterOrderModal'

const STATUS_FILTERS: { key: OrderStatus | 'all'; label: string }[] = [
  { key: 'all', label: 'Todos' },
  { key: 'pending_payment', label: 'Sin pagar' },
  { key: 'confirmed', label: 'Confirmadas' },
  { key: 'preparing', label: 'Preparando' },
  { key: 'ready', label: 'Listas' },
  { key: 'delivering', label: 'En camino' },
  { key: 'delivered', label: 'Entregadas' },
  { key: 'cancelled', label: 'Canceladas' },
]

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-AR', {
    style: 'currency',
    currency: 'ARS',
    maximumFractionDigits: 0,
  }).format(n)
}

function orderNumber(id: number) {
  return `#${String(id).padStart(5, '0')}`
}

export default function OrdersPage() {
  const navigate = useNavigate()
  const [activeFilter, setActiveFilter] = useState<OrderStatus | 'all'>('all')
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const [showCounterModal, setShowCounterModal] = useState(false)

  useOrderStatus()
  const { data, isLoading } = useOrders({
    status: activeFilter !== 'all' ? activeFilter : undefined,
    page,
  })

  const orders = data?.data ?? []
  const pagy = data?.pagy

  const filtered = search
    ? orders.filter(
        (o) =>
          orderNumber(o.id).toLowerCase().includes(search.toLowerCase()) ||
          o.user.name.toLowerCase().includes(search.toLowerCase()),
      )
    : orders

  function handleFilterChange(key: OrderStatus | 'all') {
    setActiveFilter(key)
    setPage(1)
  }

  return (
    <>
      <AdminTopbar
        title="Órdenes"
        subtitle={pagy ? `${pagy.count} órdenes en total` : undefined}
        actions={
          <button
            onClick={() => setShowCounterModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-(--color-primary) text-black text-sm font-semibold rounded-(--radius-pill)"
          >
            <Plus size={14} />
            Nueva orden
          </button>
        }
      />

      <div className="flex-1 p-8 flex flex-col gap-4 overflow-y-auto">
        {/* Search + filter bar */}
        <div className="flex items-center justify-between gap-4 flex-wrap">
          <div className="relative flex-1 max-w-sm">
            <Search
              size={14}
              className="absolute left-3 top-1/2 -translate-y-1/2 text-(--color-text-muted)"
            />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Buscar por # orden o cliente..."
              className="form-input w-full pl-9"
            />
          </div>
          <div className="flex items-center gap-1.5 flex-wrap">
            {STATUS_FILTERS.map((f) => (
              <button
                key={f.key}
                onClick={() => handleFilterChange(f.key)}
                className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  activeFilter === f.key
                    ? 'bg-(--color-primary) text-black'
                    : 'bg-(--color-surface) border border-(--color-border) text-(--color-text-secondary) hover:text-(--color-text-primary)'
                }`}
              >
                {f.label}
              </button>
            ))}
          </div>
        </div>

        {/* Table */}
        <div className="card overflow-hidden">
          {isLoading ? (
            <div className="flex items-center justify-center py-16">
              <div className="spinner" />
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-(--color-border)">
                    {['# Orden', 'Fecha', 'Cliente', 'Modalidad', 'Total', 'Ítems', 'Estado', 'Pago', 'Acciones'].map(
                      (h) => (
                        <th key={h} className="table-th">{h}</th>
                      ),
                    )}
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((order) => {
                    const isPaid = order.paid
                    return (
                      <tr key={order.id} className="table-row">
                        <td className="table-td font-mono text-xs font-semibold text-(--color-text-primary)">
                          {orderNumber(order.id)}
                        </td>
                        <td className="table-td text-(--color-text-secondary) tabular-nums text-xs">
                          {new Date(order.created_at).toLocaleString('es-AR', { day: '2-digit', month: '2-digit', year: '2-digit', hour: '2-digit', minute: '2-digit' })}
                        </td>
                        <td className="table-td text-(--color-text-primary)">{order.user.name}</td>
                        <td className="table-td">
                          <span className={`badge ${
                            order.modality === 'delivery'
                              ? 'bg-(--color-primary)/15 text-(--color-primary)'
                              : 'bg-(--color-accent)/15 text-(--color-accent)'
                          }`}>
                            {order.modality === 'delivery' ? 'Delivery' : 'Retiro'}
                          </span>
                        </td>
                        <td className="table-td font-medium text-(--color-text-primary)">
                          {formatPrice(order.total)}
                        </td>
                        <td className="table-td text-(--color-text-secondary)">
                          {order.order_items.reduce((s, i) => s + i.quantity, 0)}
                        </td>
                        <td className="table-td">
                          <span className={`badge ${ORDER_STATUS_CLASSES[order.status]}`}>
                            {ORDER_STATUS_LABEL[order.status]}
                          </span>
                        </td>
                        <td className="table-td">
                          <span className={`badge ${
                            isPaid
                              ? 'bg-(--color-primary)/15 text-(--color-primary)'
                              : 'bg-(--color-text-secondary)/15 text-(--color-text-secondary)'
                          }`}>
                            {isPaid ? 'Pagado' : 'Sin pagar'}
                          </span>
                        </td>
                        <td className="table-td">
                          <Link
                            to={`/admin/ordenes/${order.id}`}
                            className="btn-icon inline-flex"
                            title="Ver detalle"
                          >
                            <Eye size={14} />
                          </Link>
                        </td>
                      </tr>
                    )
                  })}
                  {filtered.length === 0 && (
                    <tr>
                      <td
                        colSpan={9}
                        className="px-5 py-10 text-center text-sm text-(--color-text-muted)"
                      >
                        No hay órdenes
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          )}

          {/* Pagination */}
          {pagy && pagy.pages > 1 && (
            <div className="flex items-center justify-between px-5 py-3 border-t border-(--color-border)">
              <p className="text-xs text-(--color-text-muted)">
                Mostrando {pagy.from}–{pagy.to} de {pagy.count} órdenes
              </p>
              <div className="flex items-center gap-1">
                <button
                  onClick={() => setPage((p) => p - 1)}
                  disabled={!pagy.prev}
                  className="w-7 h-7 flex items-center justify-center rounded text-(--color-text-secondary) hover:text-(--color-text-primary) hover:bg-(--color-surface-elevated) disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                >
                  <ChevronLeft size={14} />
                </button>
                {Array.from({ length: pagy.pages }, (_, i) => i + 1).map((p) => (
                  <button
                    key={p}
                    onClick={() => setPage(p)}
                    className={`w-7 h-7 flex items-center justify-center rounded text-xs transition-colors ${
                      p === page
                        ? 'bg-(--color-primary) text-black font-medium'
                        : 'text-(--color-text-secondary) hover:text-(--color-text-primary) hover:bg-(--color-surface-elevated)'
                    }`}
                  >
                    {p}
                  </button>
                ))}
                <button
                  onClick={() => setPage((p) => p + 1)}
                  disabled={!pagy.next}
                  className="w-7 h-7 flex items-center justify-center rounded text-(--color-text-secondary) hover:text-(--color-text-primary) hover:bg-(--color-surface-elevated) disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                >
                  <ChevronRight size={14} />
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {showCounterModal && (
        <CounterOrderModal
          onClose={() => setShowCounterModal(false)}
          onSuccess={(orderId) => {
            setShowCounterModal(false)
            navigate(`/admin/ordenes/${orderId}`)
          }}
        />
      )}
    </>
  )
}
