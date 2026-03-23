import { useEffect } from 'react'
import { useNavigate } from 'react-router'
import { Trash2, ArrowRight, Banknote, Building2 } from 'lucide-react'
import { sileo } from 'sileo'
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
        onError: (err) => sileo.error({ title: err.message }),
      },
    )
  }

  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] px-6 gap-4 pb-32">
        <span className="text-5xl">🛒</span>
        <p className="text-(--color-text-secondary) text-sm text-center">
          Tu carrito está vacío
        </p>
        <button
          onClick={() => navigate('/')}
          className="bg-(--color-primary) text-[#00391d] font-bold px-8 py-3 rounded-(--radius-pill) text-sm"
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
      {/* Items list */}
      <div className="px-5 pt-5 space-y-4">
        <h2 className="text-[10px] font-bold text-(--color-text-secondary) uppercase tracking-widest">
          Tu pedido
        </h2>
        {items.map((item) => (
          <div key={item.id} className="flex gap-4 items-start">
            <div className="flex-1 flex flex-col gap-1 min-w-0">
              <div className="flex justify-between items-start gap-2">
                <h3 className="font-semibold text-base text-(--color-text-primary) leading-tight">
                  {item.name}
                </h3>
                <button
                  onClick={() => removeItem(item.id)}
                  className="text-(--color-text-secondary)/40 hover:text-(--color-destructive) transition-colors shrink-0"
                >
                  <Trash2 size={18} />
                </button>
              </div>
              <div className="flex items-center justify-between mt-1">
                <span className="font-mono text-(--color-primary) font-bold text-sm">
                  {formatPrice(item.price * item.quantity)}
                </span>
                {/* Quantity controls */}
                <div className="flex items-center bg-(--color-surface) rounded-full px-1 py-1">
                  <button
                    onClick={() => setQuantity(item.id, item.quantity - 1)}
                    className="w-7 h-7 flex items-center justify-center text-(--color-text-secondary) hover:text-(--color-text-primary) transition-colors"
                  >
                    <span className="text-lg leading-none font-medium">−</span>
                  </button>
                  <span className="px-3 font-mono text-xs font-bold text-(--color-text-primary)">
                    {item.quantity}
                  </span>
                  <button
                    onClick={() => setQuantity(item.id, item.quantity + 1)}
                    className="w-7 h-7 flex items-center justify-center text-(--color-primary) hover:text-(--color-primary)/80 transition-colors"
                  >
                    <span className="text-lg leading-none font-medium">+</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Modality section */}
      <div className="px-5 mt-7">
        <div className="bg-(--color-surface) rounded-(--radius-lg) p-5">
          <label className="block text-[10px] uppercase tracking-widest text-(--color-text-secondary) font-bold mb-4">
            ¿Cómo querés recibirlo?
          </label>
          {/* Pill toggle */}
          <div className="bg-(--color-surface-low) p-1.5 rounded-full flex mb-5">
            <button
              onClick={() => setModality('delivery')}
              className={cn(
                'flex-1 py-2.5 rounded-full font-bold text-sm transition-all duration-200',
                modality === 'delivery'
                  ? 'bg-(--color-primary) text-[#00391d] shadow-sm'
                  : 'text-(--color-text-secondary)',
              )}
            >
              🛵 Delivery
            </button>
            <button
              onClick={() => setModality('pickup')}
              className={cn(
                'flex-1 py-2.5 rounded-full font-bold text-sm transition-all duration-200',
                modality === 'pickup'
                  ? 'bg-(--color-primary) text-[#00391d] shadow-sm'
                  : 'text-(--color-text-secondary)',
              )}
            >
              🏪 Retiro
            </button>
          </div>

          {/* Address input for delivery */}
          {modality === 'delivery' && (
            <div className="space-y-3">
              <AddressSearchInput value={address} onChange={setAddress} />
              {user?.default_address && address !== user.default_address && (
                <button
                  onClick={() => setAddress(user.default_address!)}
                  className="flex items-center gap-2 px-4 py-2 bg-(--color-primary)/5 rounded-full"
                >
                  <span className="text-[11px] font-bold text-(--color-primary) uppercase tracking-tight">
                    Usar: {user.default_address}
                  </span>
                  <ArrowRight size={12} className="text-(--color-primary)" />
                </button>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Payment method */}
      <div className="px-5 mt-5">
        <div className="bg-(--color-surface) rounded-(--radius-lg) p-5">
          <label className="block text-[10px] uppercase tracking-widest text-(--color-text-secondary) font-bold mb-4">
            Medio de pago
          </label>
          <div className="grid grid-cols-2 gap-3">
            {(
              [
                {
                  key: 'cash',
                  label: 'Efectivo',
                  sub: 'Al recibir',
                  icon: Banknote,
                },
                {
                  key: 'transfer',
                  label: 'Transf. MP',
                  sub: 'twobrothers.mp',
                  icon: Building2,
                },
              ] as const
            ).map(({ key, label, sub, icon: Icon }) => (
              <button
                key={key}
                onClick={() => setPaymentMethod(key)}
                className={cn(
                  'flex flex-col items-center justify-center p-4 rounded-(--radius-lg) border transition-all active:scale-[0.98]',
                  paymentMethod === key
                    ? 'bg-(--color-surface-elevated) border-(--color-primary)/40 shadow-[0_0_12px_rgba(97,230,152,0.08)]'
                    : 'bg-(--color-surface-low) border-transparent',
                )}
              >
                <Icon
                  size={22}
                  className={cn(
                    'mb-2 transition-colors',
                    paymentMethod === key
                      ? 'text-(--color-primary)'
                      : 'text-(--color-text-secondary)',
                  )}
                />
                <span
                  className={cn(
                    'text-xs font-semibold transition-colors',
                    paymentMethod === key
                      ? 'text-(--color-text-primary)'
                      : 'text-(--color-text-secondary)',
                  )}
                >
                  {label}
                </span>
                <span className="text-[10px] text-(--color-text-secondary) mt-0.5 font-mono truncate w-full text-center">
                  {sub}
                </span>
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Order summary receipt */}
      <div className="px-5 mt-5">
        <div className="bg-(--color-surface-lowest) rounded-(--radius-lg) p-6 border-l-4 border-(--color-primary)">
          <h3 className="font-mono text-[10px] uppercase tracking-[0.2em] text-(--color-text-secondary) mb-4">
            Resumen del pedido
          </h3>
          <div className="space-y-2 font-mono text-sm">
            {items.map((item) => (
              <div key={item.id} className="flex justify-between">
                <span className="text-(--color-text-secondary)">
                  {item.quantity}× {item.name}
                </span>
                <span className="text-(--color-text-primary)">
                  {formatPrice(item.price * item.quantity)}
                </span>
              </div>
            ))}
            {deliveryFee > 0 && (
              <div className="flex justify-between text-(--color-text-secondary)">
                <span>Envío</span>
                <span>{formatPrice(deliveryFee)}</span>
              </div>
            )}
            <div className="pt-3 mt-2 border-t border-(--color-border)/30 flex justify-between items-baseline">
              <span className="text-sm font-bold text-(--color-text-primary) tracking-widest uppercase">
                Total
              </span>
              <span className="text-2xl font-bold text-(--color-primary)">
                {formatPrice(total)}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* CTA */}
      <div className="px-5 mt-6">
        <button onClick={handleConfirm} disabled={!canConfirm} className="btn-cta">
          {createOrder.isPending ? (
            <span className="animate-spin rounded-full border-2 border-[#00391d]/30 border-t-[#00391d] w-5 h-5" />
          ) : (
            <>
              Hacer el pedido
              <ArrowRight size={18} />
            </>
          )}
        </button>
        {modality === 'delivery' && !address.trim() && (
          <p className="text-xs text-(--color-text-secondary) text-center mt-3">
            Ingresá tu dirección para continuar
          </p>
        )}
      </div>
    </div>
  )
}
