import { useState } from 'react'
import { X, Plus, Minus, ShoppingBag } from 'lucide-react'
import { cn } from '@/lib/utils'
import { useCategories } from '@/api/categories'
import { useCreateCounterOrder } from '@/api/orders'
import type { PaymentMethod } from '@/types/orders'

interface Props {
  onClose: () => void
  onSuccess: (orderId: number) => void
}

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-AR', {
    style: 'currency', currency: 'ARS', maximumFractionDigits: 0,
  }).format(n)
}

export default function CounterOrderModal({ onClose, onSuccess }: Props) {
  const { data: categories } = useCategories()
  const createCounter = useCreateCounterOrder()

  const [quantities, setQuantities] = useState<Record<number, number>>({})
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>('cash')

  const items = (categories ?? [])
    .flatMap((c) => c.menu_items)
    .filter((m) => m.available)

  function setQty(id: number, delta: number) {
    setQuantities((prev) => {
      const next = (prev[id] ?? 0) + delta
      if (next <= 0) {
        const { [id]: _, ...rest } = prev
        return rest
      }
      return { ...prev, [id]: next }
    })
  }

  const selectedItems = items.filter((m) => (quantities[m.id] ?? 0) > 0)
  const totalChickens = selectedItems.reduce((s, m) => s + (quantities[m.id] ?? 0), 0)
  const totalPrice = selectedItems.reduce(
    (s, m) => s + m.price * (quantities[m.id] ?? 0), 0
  )
  const canSubmit = selectedItems.length > 0 && totalChickens <= 4

  function handleSubmit() {
    createCounter.mutate(
      {
        payment_method: paymentMethod,
        order_items_attributes: selectedItems.map((m) => ({
          menu_item_id: m.id,
          quantity: quantities[m.id],
          unit_price: m.price,
        })),
      },
      { onSuccess: (order) => onSuccess(order.id) },
    )
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
      <div className="bg-(--color-surface) rounded-(--radius-lg) border border-(--color-border) w-full max-w-lg flex flex-col max-h-[90vh]">

        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-(--color-border) shrink-0">
          <div className="flex items-center gap-2">
            <ShoppingBag size={16} className="text-(--color-primary)" />
            <h2 className="font-semibold text-(--color-text-primary)">Nueva orden — Mostrador</h2>
          </div>
          <button
            onClick={onClose}
            className="w-7 h-7 flex items-center justify-center rounded-lg text-(--color-text-muted) hover:text-(--color-text-primary) hover:bg-(--color-surface-elevated) transition-colors"
          >
            <X size={15} />
          </button>
        </div>

        {/* Items */}
        <div className="flex-1 overflow-y-auto px-6 py-4 flex flex-col gap-4">
          {(categories ?? []).map((cat) => {
            const available = cat.menu_items.filter((m) => m.available)
            if (available.length === 0) return null
            return (
              <div key={cat.id}>
                <p className="text-xs font-semibold text-(--color-text-muted) uppercase tracking-wider mb-2">
                  {cat.name}
                </p>
                <div className="flex flex-col gap-1.5">
                  {available.map((item) => {
                    const qty = quantities[item.id] ?? 0
                    return (
                      <div
                        key={item.id}
                        className={cn(
                          'flex items-center justify-between px-4 py-3 rounded-(--radius-lg) border transition-colors',
                          qty > 0
                            ? 'bg-(--color-primary)/8 border-(--color-primary)/30'
                            : 'bg-(--color-surface-elevated) border-(--color-border)',
                        )}
                      >
                        <div>
                          <p className="text-sm font-medium text-(--color-text-primary)">{item.name}</p>
                          <p className="text-xs text-(--color-text-secondary)">{formatPrice(item.price)}</p>
                        </div>
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => setQty(item.id, -1)}
                            disabled={qty === 0}
                            className="w-7 h-7 rounded-full bg-(--color-surface) border border-(--color-border) flex items-center justify-center text-(--color-text-secondary) disabled:opacity-30 hover:text-(--color-text-primary) transition-colors"
                          >
                            <Minus size={12} />
                          </button>
                          <span className="w-5 text-center text-sm font-bold text-(--color-text-primary)">
                            {qty || '·'}
                          </span>
                          <button
                            onClick={() => setQty(item.id, 1)}
                            disabled={totalChickens >= 4}
                            className="w-7 h-7 rounded-full bg-(--color-surface) border border-(--color-border) flex items-center justify-center text-(--color-text-secondary) disabled:opacity-30 hover:text-(--color-text-primary) transition-colors"
                          >
                            <Plus size={12} />
                          </button>
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>
            )
          })}
        </div>

        {/* Footer */}
        <div className="border-t border-(--color-border) px-6 py-4 shrink-0 flex flex-col gap-3">
          {/* Payment method */}
          <div className="grid grid-cols-2 gap-2">
            {(['cash', 'transfer'] as PaymentMethod[]).map((m) => (
              <button
                key={m}
                onClick={() => setPaymentMethod(m)}
                className={cn(
                  'py-2 rounded-(--radius-lg) text-sm font-medium border transition-colors',
                  paymentMethod === m
                    ? 'bg-(--color-primary)/15 border-(--color-primary)/50 text-(--color-primary)'
                    : 'bg-(--color-surface-elevated) border-(--color-border) text-(--color-text-secondary)',
                )}
              >
                {m === 'cash' ? '💵 Efectivo' : '📲 Transferencia'}
              </button>
            ))}
          </div>

          {/* Total + limit hint */}
          <div className="flex items-center justify-between">
            <div>
              <span className="text-xs text-(--color-text-muted)">
                {totalChickens}/4 pollos
              </span>
              {createCounter.isError && (
                <p className="text-xs text-red-400 mt-0.5">{createCounter.error.message}</p>
              )}
            </div>
            <span className="text-lg font-bold text-(--color-primary)">{formatPrice(totalPrice)}</span>
          </div>

          <button
            onClick={handleSubmit}
            disabled={!canSubmit || createCounter.isPending}
            className="w-full bg-(--color-primary) text-black font-semibold py-3 rounded-(--radius-pill) disabled:opacity-50 transition-opacity flex items-center justify-center gap-2"
          >
            {createCounter.isPending
              ? <span className="animate-spin rounded-full border-2 border-black border-t-transparent w-4 h-4" />
              : 'Confirmar orden'}
          </button>
        </div>
      </div>
    </div>
  )
}
