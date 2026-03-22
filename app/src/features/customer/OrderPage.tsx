import { useParams, Link } from 'react-router'
import { Clock, CheckCircle2, ChefHat, Package, Bike, Check, Copy } from 'lucide-react'
import { cn } from '@/lib/utils'
import MapView from '@/components/MapView'
import { useOrder } from '@/api/orders'
import { useLatestLocation } from '@/api/deliveryLocations'
import { useOrderStatus } from '@/hooks/useOrderStatus'

const STEPS = [
  { key: 'pending_payment', label: 'Pendiente de pago', icon: Clock },
  { key: 'confirmed',       label: 'Confirmada',        icon: CheckCircle2 },
  { key: 'preparing',       label: 'En preparación',    icon: ChefHat },
  { key: 'ready',           label: 'Lista para despachar', icon: Package },
  { key: 'delivering',      label: 'En camino',         icon: Bike },
  { key: 'delivered',       label: 'Entregada',         icon: Check },
] as const

type StepKey = (typeof STEPS)[number]['key']

const STATUS_ORDER: StepKey[] = [
  'pending_payment', 'confirmed', 'preparing', 'ready', 'delivering', 'delivered',
]

// Coordenadas del local
const LOCAL_COORDS: [number, number] = [-57.6833, -36.3192]

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-AR', {
    style: 'currency', currency: 'ARS', maximumFractionDigits: 0,
  }).format(n)
}

export default function OrderPage() {
  const { id } = useParams()
  const { data: order, isLoading } = useOrder(id!)
  useOrderStatus(id)
  const { data: location } = useLatestLocation(
    order?.status === 'delivering' ? order.delivery_assignment_id ?? undefined : undefined
  )

  if (isLoading || !order) {
    return (
      <div className="pb-32 max-w-lg mx-auto px-5 pt-8 flex items-center justify-center min-h-[50vh]">
        <div className="w-8 h-8 rounded-full border-2 border-(--color-border) border-t-(--color-primary) animate-spin" />
      </div>
    )
  }

  const currentStep = STATUS_ORDER.indexOf(order.status as StepKey)
  const isDelivering = order.status === 'delivering'

  const deliveryCoords: [number, number] | null = location
    ? [Number(location.longitude), Number(location.latitude)]
    : null

  const mapCenter: [number, number] = deliveryCoords
    ? [(LOCAL_COORDS[0] + deliveryCoords[0]) / 2, (LOCAL_COORDS[1] + deliveryCoords[1]) / 2]
    : LOCAL_COORDS

  return (
    <div className="pb-32 max-w-lg mx-auto px-5 pt-5">
      {/* Status header */}
      <section className="mb-7">
        {isDelivering && (
          <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-(--color-accent-container) text-(--color-accent) rounded-full mb-4 animate-status-pulse">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-(--color-accent) opacity-75" />
              <span className="relative inline-flex rounded-full h-2 w-2 bg-(--color-accent)" />
            </span>
            <span className="font-mono text-[10px] font-bold tracking-widest uppercase">
              En camino
            </span>
          </div>
        )}

        <div className="flex items-start justify-between gap-3">
          <div className="flex-1">
            <h2 className="text-3xl font-bold tracking-tight text-(--color-text-primary) leading-tight mb-1">
              {isDelivering
                ? 'Tu pedido está en camino'
                : order.status === 'delivered'
                  ? '¡Pedido entregado!'
                  : order.status === 'pending_payment'
                    ? 'Esperando confirmación'
                    : `Pedido ${order.status === 'confirmed' ? 'confirmado' : order.status === 'preparing' ? 'en preparación' : 'listo'}`}
            </h2>
            <p className="text-(--color-text-secondary) text-sm">
              {order.modality === 'delivery'
                ? `Entrega en ${order.delivery_address}`
                : 'Retiro en local'}{' '}
              ·{' '}
              <span className="font-mono">
                #{String(order.id).padStart(5, '0')}
              </span>
            </p>
          </div>
          <span className="text-xs text-(--color-text-secondary) shrink-0 font-mono">
            {new Date(order.created_at).toLocaleTimeString('es-AR', {
              hour: '2-digit',
              minute: '2-digit',
            })} hs
          </span>
        </div>
      </section>

      {/* Payment instructions (if pending) */}
      {order.status === 'pending_payment' && (
        <div className="bg-[#3D2E10] border border-(--color-accent)/40 rounded-(--radius-lg) p-5 mb-6">
          <p className="text-sm font-semibold text-(--color-accent) mb-2">
            Esperando confirmación de pago
          </p>
          {order.payment_method === 'transfer' ? (
            <>
              <p className="text-xs text-(--color-accent)/80 mb-3">
                Realizá la transferencia a:
              </p>
              <div className="bg-(--color-background)/40 rounded-(--radius-md) px-4 py-3 flex items-center justify-between">
                <span className="font-mono text-sm text-(--color-text-primary)">
                  twobrothers.mp
                </span>
                <button className="text-(--color-text-secondary) hover:text-(--color-text-primary) transition-colors">
                  <Copy size={14} />
                </button>
              </div>
              <p className="text-xs text-(--color-text-secondary) mt-2">
                Monto:{' '}
                <strong className="text-(--color-text-primary)">
                  {formatPrice(order.total)}
                </strong>
                {' · '}Referencia: #{String(order.id).padStart(5, '0')}
              </p>
            </>
          ) : (
            <p className="text-xs text-(--color-accent)/80">
              Pagás en efectivo al momento de recibir o retirar tu pedido.
            </p>
          )}
        </div>
      )}

      {/* Live map — only while delivering */}
      {isDelivering && (
        <section className="mb-7">
          <div className="relative w-full h-52 rounded-(--radius-lg) overflow-hidden bg-(--color-surface-low) shadow-xl">
            <MapView
              center={mapCenter}
              zoom={14}
              routeFrom={deliveryCoords ?? LOCAL_COORDS}
              routeTo={LOCAL_COORDS}
              markers={[
                ...(deliveryCoords
                  ? [{ lngLat: deliveryCoords, kind: 'delivery' as const, tooltip: 'Repartidor' }]
                  : []),
                { lngLat: LOCAL_COORDS, kind: 'origin' as const, tooltip: 'Local' },
              ]}
              className="absolute inset-0"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-(--color-background)/30 to-transparent pointer-events-none" />
          </div>
        </section>
      )}

      {/* Status timeline */}
      <section className="mb-7">
        <div className="bg-(--color-surface) rounded-(--radius-lg) p-5">
          <h3 className="text-[10px] font-bold uppercase tracking-widest text-(--color-text-secondary) mb-5">
            Estado del pedido
          </h3>
          <div className="relative px-1">
            {/* Vertical line */}
            <div className="absolute left-4 top-2 bottom-2 w-px bg-(--color-border)/40" />

            <div className="space-y-6">
              {STEPS.map((step, idx) => {
                const Icon = step.icon
                const done = idx < currentStep
                const active = idx === currentStep

                return (
                  <div key={step.key} className="flex items-center gap-5 relative">
                    <div
                      className={cn(
                        'z-10 w-8 h-8 rounded-full flex items-center justify-center shrink-0 transition-all',
                        done
                          ? 'bg-(--color-primary-muted) text-(--color-primary)'
                          : active
                            ? isDelivering && step.key === 'delivering'
                              ? 'bg-(--color-accent) text-[#4e2600] shadow-[0_0_16px_rgba(255,183,128,0.4)] animate-status-pulse'
                              : 'bg-(--color-primary) text-[#00391d]'
                            : 'bg-(--color-surface-elevated) text-(--color-text-muted)',
                      )}
                    >
                      <Icon size={14} />
                    </div>
                    <div>
                      <p
                        className={cn(
                          'text-sm font-medium transition-colors',
                          active
                            ? isDelivering && step.key === 'delivering'
                              ? 'text-(--color-accent) font-bold uppercase tracking-wide'
                              : 'text-(--color-text-primary) font-bold'
                            : done
                              ? 'text-(--color-text-secondary)'
                              : 'text-(--color-text-muted)',
                        )}
                      >
                        {step.label}
                      </p>
                    </div>
                  </div>
                )
              })}
            </div>
          </div>
        </div>
      </section>

      {/* Order summary — "The Ticket" */}
      <section className="mb-6">
        <h3 className="font-mono text-[10px] uppercase tracking-[0.2em] text-(--color-text-secondary) mb-3 px-1">
          Detalle del pedido
        </h3>
        <div className="bg-(--color-surface-lowest) rounded-(--radius-lg) p-6 border-t-2 border-dashed border-(--color-border)/30 relative overflow-hidden">
          {/* Ticket punch holes */}
          <div className="absolute -left-3 top-1/2 -translate-y-1/2 w-6 h-6 bg-(--color-background) rounded-full" />
          <div className="absolute -right-3 top-1/2 -translate-y-1/2 w-6 h-6 bg-(--color-background) rounded-full" />

          <div className="space-y-3 font-mono text-xs">
            {order.order_items.map((item) => (
              <div key={item.id} className="flex justify-between items-center">
                <span className="text-(--color-text-secondary)">
                  {item.quantity}× {item.name}
                </span>
                <span className="text-(--color-text-primary)">
                  {formatPrice(Number(item.unit_price) * item.quantity)}
                </span>
              </div>
            ))}
            {Number(order.delivery_fee) > 0 && (
              <div className="flex justify-between items-center">
                <span className="text-(--color-text-secondary)">Envío</span>
                <span className="text-(--color-text-primary)">
                  {formatPrice(Number(order.delivery_fee))}
                </span>
              </div>
            )}
            <div className="pt-3 mt-2 border-t border-(--color-border)/20">
              <div className="flex justify-between items-center">
                <span className="text-(--color-text-primary) font-bold text-sm tracking-widest uppercase">
                  Total
                </span>
                <span className="text-(--color-primary) font-bold text-lg tracking-tighter">
                  {formatPrice(order.total + Number(order.delivery_fee))}
                </span>
              </div>
            </div>
          </div>

          {/* Barcode decoration */}
          <div className="mt-6 flex flex-col items-center">
            <div className="w-full h-6 opacity-[0.07] bg-[repeating-linear-gradient(90deg,#bccabd,#bccabd_2px,transparent_2px,transparent_6px)]" />
            <p className="text-[9px] text-(--color-text-secondary)/40 mt-2 font-mono uppercase tracking-widest">
              ORDER #{String(order.id).padStart(5, '0')}
            </p>
          </div>
        </div>
      </section>

      <Link
        to="/historial"
        className="block text-center text-sm text-(--color-text-secondary) py-2 hover:text-(--color-primary) transition-colors"
      >
        Ver mis pedidos anteriores →
      </Link>
    </div>
  )
}
