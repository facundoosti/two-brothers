import { Link } from 'react-router'
import { ChevronRight } from 'lucide-react'
import { ORDER_STATUS_LABEL, ORDER_STATUS_CLASSES } from '@/lib/status'
import { cn } from '@/lib/utils'
import { useOrders } from '@/api/orders'

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-AR', {
    style: 'currency',
    currency: 'ARS',
    maximumFractionDigits: 0,
  }).format(n)
}

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString('es-AR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })
}

function orderNumber(id: number) {
  return `#${String(id).padStart(5, '0')}`
}

export default function HistoryPage() {
  const { data, isLoading } = useOrders()
  const orders = data?.data ?? []

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="w-7 h-7 rounded-full border-2 border-(--color-text-muted) border-t-(--color-primary) animate-spin" />
      </div>
    )
  }

  return (
    <div className="max-w-lg mx-auto px-4 pt-4 pb-10">
      <h1 className="text-lg font-bold text-(--color-text-primary) mb-4">Mis pedidos</h1>

      {orders.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-20 gap-3">
          <span className="text-4xl">📋</span>
          <p className="text-sm text-(--color-text-secondary)">Todavía no hiciste ningún pedido</p>
          <Link to="/" className="text-sm text-(--color-primary) font-medium">
            Ver menú
          </Link>
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          {orders.map((order) => (
            <Link
              key={order.id}
              to={`/pedido/${order.id}`}
              className="bg-(--color-surface) rounded-(--radius-lg) p-4 flex items-center gap-3 group"
            >
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <span className="font-mono text-sm font-semibold text-(--color-text-primary)">
                    {orderNumber(order.id)}
                  </span>
                  <span
                    className={cn(
                      'text-xs px-2 py-0.5 rounded-full font-medium',
                      ORDER_STATUS_CLASSES[order.status],
                    )}
                  >
                    {ORDER_STATUS_LABEL[order.status]}
                  </span>
                </div>

                <p className="text-xs text-(--color-text-secondary) truncate">
                  {order.order_items.map((i) => `${i.quantity}×`).join(', ')}
                </p>

                <div className="flex items-center gap-2 mt-1.5">
                  <span className="text-xs text-(--color-text-muted)">
                    {formatDate(order.created_at)}
                  </span>
                  <span className="text-(--color-border)">·</span>
                  <span className="text-xs text-(--color-text-muted)">
                    {order.modality === 'delivery' ? 'Delivery' : 'Retiro'}
                  </span>
                </div>
              </div>

              <div className="flex flex-col items-end gap-1 shrink-0">
                <span className="text-sm font-bold text-(--color-text-primary)">
                  {formatPrice(order.total)}
                </span>
                <ChevronRight
                  size={15}
                  className="text-(--color-text-muted) group-hover:text-(--color-text-secondary) transition-colors"
                />
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  )
}
