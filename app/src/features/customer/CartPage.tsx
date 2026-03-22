import { useEffect } from 'react'
import { useNavigate } from 'react-router'
import { Trash2, ChevronRight } from 'lucide-react'
import { useCartStore } from '@/store/cartStore'
import { useAuthStore } from '@/store/authStore'
import { cn } from '@/lib/utils'
import { AddressSearchInput } from '@/components/AddressSearchInput'
import { useCreateOrder } from '@/api/orders'
import { useStoreStatus } from '@/api/storeStatus'

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-AR', {
    style: 'currency',
    currency: 'ARS',
    maximumFractionDigits: 0,
  }).format(n)
}

export default function CartPage() {
  const navigate = useNavigate()
  const {
    items,
    modality,
    address,
    paymentMethod,
    setQuantity,
    removeItem,
    setModality,
    setAddress,
    setPaymentMethod,
    clearCart,
  } = useCartStore()
  const { user, updateDefaultAddress } = useAuthStore()
  const createOrder = useCreateOrder()
  const { data: status } = useStoreStatus()

  useEffect(() => {
    if (modality === 'delivery' && !address && user?.default_address) {
      setAddress(user.default_address)
    }
  }, [modality, address, user?.default_address, setAddress])

  const subtotal = items.reduce((sum, i) => sum + i.price * i.quantity, 0)
  const deliveryFee =
    modality === 'delivery' && status?.delivery_fee_enabled ? status.delivery_fee : 0
  const total = subtotal + deliveryFee

  function handleConfirm() {
    createOrder.mutate(
      {
        modality,
        payment_method: paymentMethod,
        ...(modality === 'delivery' ? { delivery_address: address } : {}),
        order_items_attributes: items.map((i) => ({
          menu_item_id: i.id,
          quantity: i.quantity,
          unit_price: i.price,
        })),
      },
      {
        onSuccess: (order) => {
          if (modality === 'delivery' && address) updateDefaultAddress(address)
          clearCart()
          navigate(`/pedido/${order.id}`)
        },
      },
    )
  }

  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] px-6 gap-4">
        <span className="text-5xl">🛒</span>
        <p className="text-(--color-text-secondary) text-sm text-center">
          Tu carrito está vacío
        </p>
        <button
          onClick={() => navigate('/')}
          className="bg-(--color-primary) text-(--color-background) font-semibold px-6 py-2.5 rounded-(--radius-pill) text-sm"
        >
          Ver menú
        </button>
      </div>
    )
  }

  const canConfirm =
    (modality === 'pickup' || address.trim().length > 0) && !createOrder.isPending

  return (
    <div className="pb-36 max-w-lg mx-auto">
      {/* Items */}
      <div className="px-4 pt-4 flex flex-col gap-2">
        <h2 className="text-xs font-semibold text-(--color-text-muted) uppercase tracking-wider mb-1">
          Tu pedido
        </h2>
        {items.map((item) => (
          <div
            key={item.id}
            className="bg-(--color-surface) rounded-(--radius-lg) p-4 flex items-center gap-3"
          >
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-(--color-text-primary)">{item.name}</p>
              <p className="text-xs text-(--color-text-secondary) mt-0.5">
                {formatPrice(item.price)} c/u
              </p>
            </div>

            {/* Quantity controls */}
            <div className="flex items-center gap-2">
              <button
                onClick={() => setQuantity(item.id, item.quantity - 1)}
                className="w-7 h-7 rounded-full bg-(--color-surface-elevated) flex items-center justify-center text-(--color-text-primary) font-bold text-base leading-none"
              >
                −
              </button>
              <span className="w-5 text-center text-sm font-bold text-(--color-text-primary)">
                {item.quantity}
              </span>
              <button
                onClick={() => setQuantity(item.id, item.quantity + 1)}
                className="w-7 h-7 rounded-full bg-(--color-surface-elevated) flex items-center justify-center text-(--color-text-primary) font-bold text-base leading-none"
              >
                +
              </button>
            </div>

            {/* Subtotal + remove */}
            <div className="flex flex-col items-end gap-1 shrink-0">
              <span className="text-sm font-semibold text-(--color-text-primary)">
                {formatPrice(item.price * item.quantity)}
              </span>
              <button
                onClick={() => removeItem(item.id)}
                className="text-(--color-destructive) opacity-70 hover:opacity-100"
              >
                <Trash2 size={13} />
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Modality */}
      <div className="px-4 mt-5">
        <h2 className="text-xs font-semibold text-(--color-text-muted) uppercase tracking-wider mb-2">
          ¿Cómo querés recibirlo?
        </h2>
        <div className="grid grid-cols-2 gap-2">
          {(
            [
              { key: 'delivery', label: '🛵 Delivery' },
              { key: 'pickup', label: '🏪 Retiro en local' },
            ] as const
          ).map(({ key, label }) => (
            <button
              key={key}
              onClick={() => setModality(key)}
              className={cn(
                'py-3 rounded-(--radius-lg) text-sm font-semibold border transition-colors',
                modality === key
                  ? 'bg-(--color-primary-muted) border-(--color-primary) text-(--color-primary)'
                  : 'bg-(--color-surface) border-(--color-border) text-(--color-text-secondary)',
              )}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* Address */}
      {modality === 'delivery' && (
        <div className="px-4 mt-4">
          <h2 className="text-xs font-semibold text-(--color-text-muted) uppercase tracking-wider mb-2">
            Dirección de entrega
          </h2>
          <AddressSearchInput value={address} onChange={setAddress} />
        </div>
      )}

      {/* Payment method */}
      <div className="px-4 mt-5">
        <h2 className="text-xs font-semibold text-(--color-text-muted) uppercase tracking-wider mb-2">
          Medio de pago
        </h2>
        <div className="bg-(--color-surface) rounded-(--radius-lg) overflow-hidden">
          {(
            [
              {
                key: 'cash',
                label: 'Efectivo',
                emoji: '💵',
                sub: 'Pagás al momento de recibir o retirar',
              },
              {
                key: 'transfer',
                label: 'Transferencia',
                emoji: '📲',
                sub: 'Alias MP: twobrothers.mp',
              },
            ] as const
          ).map(({ key, label, emoji, sub }) => (
            <button
              key={key}
              onClick={() => setPaymentMethod(key)}
              className={cn(
                'w-full flex items-center gap-3 px-4 py-3.5 text-left border-b border-(--color-border) last:border-0 transition-colors',
                paymentMethod === key ? 'bg-(--color-primary-muted)' : '',
              )}
            >
              <span className="text-xl">{emoji}</span>
              <div className="flex-1">
                <p
                  className={cn(
                    'text-sm font-medium',
                    paymentMethod === key
                      ? 'text-(--color-primary)'
                      : 'text-(--color-text-primary)',
                  )}
                >
                  {label}
                </p>
                <p className="text-xs text-(--color-text-secondary) mt-0.5">{sub}</p>
              </div>
              <div
                className={cn(
                  'w-4 h-4 rounded-full border-2 shrink-0 transition-colors',
                  paymentMethod === key
                    ? 'border-(--color-primary) bg-(--color-primary)'
                    : 'border-(--color-border)',
                )}
              />
            </button>
          ))}
        </div>
      </div>

      {/* Fixed bottom: total + CTA */}
      <div className="fixed bottom-0 left-0 right-0 px-4 pb-4 pt-3 bg-(--color-background) border-t border-(--color-border)">
        <div className="max-w-lg mx-auto flex flex-col gap-1 mb-3">
          {deliveryFee > 0 && (
            <div className="flex justify-between items-center">
              <span className="text-(--color-text-secondary) text-sm">Subtotal</span>
              <span className="text-(--color-text-secondary) text-sm">{formatPrice(subtotal)}</span>
            </div>
          )}
          {deliveryFee > 0 && (
            <div className="flex justify-between items-center">
              <span className="text-(--color-text-secondary) text-sm">Envío</span>
              <span className="text-(--color-text-secondary) text-sm">{formatPrice(deliveryFee)}</span>
            </div>
          )}
          <div className="flex justify-between items-center">
            <span className="text-(--color-text-secondary) text-sm">Total</span>
            <span className="text-(--color-text-primary) font-bold text-lg">{formatPrice(total)}</span>
          </div>
        </div>
        <div className="max-w-lg mx-auto">
          <button
            onClick={handleConfirm}
            disabled={!canConfirm}
            className="w-full bg-(--color-primary) text-(--color-background) font-semibold py-3.5 rounded-(--radius-pill) disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            {createOrder.isPending ? (
              <span className="animate-spin rounded-full border-2 border-(--color-background) border-t-transparent w-4 h-4" />
            ) : (
              <>
                Confirmar pedido
                <ChevronRight size={16} />
              </>
            )}
          </button>
          {modality === 'delivery' && !address.trim() && (
            <p className="text-xs text-(--color-text-muted) text-center mt-2">
              Ingresá tu dirección para continuar
            </p>
          )}
          {createOrder.isError && (
            <p className="text-xs text-red-400 text-center mt-2">
              {createOrder.error.message}
            </p>
          )}
        </div>
      </div>
    </div>
  )
}
