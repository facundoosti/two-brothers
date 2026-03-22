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
      <div className="pb-10 max-w-lg mx-auto px-4 pt-4">
        <div className="bg-(--color-surface) rounded-(--radius-lg) p-8 text-center">
          <p className="text-sm text-(--color-text-muted)">Cargando pedido...</p>
        </div>
      </div>
    )
  }

  const currentStep = STATUS_ORDER.indexOf(order.status as StepKey)

  const deliveryCoords: [number, number] | null = location
    ? [Number(location.longitude), Number(location.latitude)]
    : null

  const mapCenter: [number, number] = deliveryCoords
    ? [(LOCAL_COORDS[0] + deliveryCoords[0]) / 2, (LOCAL_COORDS[1] + deliveryCoords[1]) / 2]
    : LOCAL_COORDS

  return (
    <div className="pb-10 max-w-lg mx-auto px-4 pt-4">
      {/* Order header */}
      <div className="bg-(--color-surface) rounded-(--radius-lg) p-4 mb-4 flex items-center justify-between">
        <div>
          <span className="font-mono font-semibold text-(--color-text-primary)">
            #{String(order.id).padStart(4, '0')}
          </span>
          <p className="text-xs text-(--color-text-secondary) mt-0.5">
            {order.modality === 'delivery'
              ? `Entrega en ${order.delivery_address}`
              : 'Retiro en local'}
          </p>
        </div>
        <span className="text-xs text-(--color-text-muted)">
          {new Date(order.created_at).toLocaleTimeString('es-AR', { hour: '2-digit', minute: '2-digit' })} hs
        </span>
      </div>

      {/* Payment instructions (if pending) */}
      {order.status === 'pending_payment' && (
        <div className="bg-[#3D2E10] border border-(--color-accent)/40 rounded-(--radius-lg) p-4 mb-4">
          <p className="text-sm font-semibold text-(--color-accent) mb-2">
            Esperando confirmación de pago
          </p>
          {order.payment_method === 'transfer' ? (
            <>
              <p className="text-xs text-(--color-accent)/80 mb-2">Realizá la transferencia a:</p>
              <div className="bg-(--color-background)/40 rounded-(--radius-md) px-3 py-2.5 flex items-center justify-between">
                <span className="font-mono text-sm text-(--color-text-primary)">twobrothers.mp</span>
                <button className="text-(--color-text-muted) hover:text-(--color-text-secondary)">
                  <Copy size={13} />
                </button>
              </div>
              <p className="text-xs text-(--color-text-secondary) mt-2">
                Monto: <strong className="text-(--color-text-primary)">{formatPrice(order.total)}</strong>
                {' · '}Referencia: #{String(order.id).padStart(4, '0')}
              </p>
            </>
          ) : (
            <p className="text-xs text-(--color-accent)/80">
              Pagás en efectivo al momento de recibir o retirar tu pedido.
            </p>
          )}
        </div>
      )}

      {/* Status timeline */}
      <div className="bg-(--color-surface) rounded-(--radius-lg) p-4 mb-4">
        <h3 className="text-xs font-semibold text-(--color-text-muted) uppercase tracking-wider mb-4">
          Estado del pedido
        </h3>
        <div className="flex flex-col">
          {STEPS.map((step, idx) => {
            const Icon = step.icon
            const done = idx < currentStep
            const active = idx === currentStep

            return (
              <div key={step.key} className="flex items-start gap-3">
                <div className="flex flex-col items-center">
                  <div className={cn(
                    'w-7 h-7 rounded-full flex items-center justify-center shrink-0',
                    done ? 'bg-(--color-primary-muted) text-(--color-primary)'
                      : active ? 'bg-(--color-primary) text-(--color-background)'
                      : 'bg-(--color-surface-elevated) text-(--color-text-muted)',
                  )}>
                    <Icon size={13} />
                  </div>
                  {idx < STEPS.length - 1 && (
                    <div className={cn('w-0.5 h-6 my-0.5', done ? 'bg-(--color-primary)/30' : 'bg-(--color-border)')} />
                  )}
                </div>
                <div className="pt-1 pb-1">
                  <p className={cn(
                    'text-sm font-medium',
                    active ? 'text-(--color-text-primary)' : done ? 'text-(--color-text-secondary)' : 'text-(--color-text-muted)',
                  )}>
                    {step.label}
                  </p>
                </div>
              </div>
            )
          })}
        </div>
      </div>

      {/* Live map — only while delivering */}
      {order.status === 'delivering' && (
        <div className="bg-(--color-surface) rounded-(--radius-lg) mb-4 overflow-hidden">
          <div className="px-4 pt-4 pb-2 flex items-center justify-between">
            <h3 className="text-xs font-semibold text-(--color-text-muted) uppercase tracking-wider">
              Seguimiento en vivo
            </h3>
            <div className="flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-(--color-primary) animate-pulse" />
              <span className="text-[11px] text-(--color-primary) font-medium">En camino</span>
            </div>
          </div>
          <div className="relative h-44 mx-4 mb-4 rounded-xl overflow-hidden border border-(--color-border)">
            <MapView
              center={mapCenter}
              zoom={14}
              routeFrom={deliveryCoords ?? LOCAL_COORDS}
              routeTo={LOCAL_COORDS}
              markers={[
                ...(deliveryCoords ? [{ lngLat: deliveryCoords, kind: 'delivery' as const, tooltip: 'Repartidor' }] : []),
                { lngLat: LOCAL_COORDS, kind: 'origin' as const, tooltip: 'Local' },
              ]}
              className="absolute inset-0"
            />
          </div>
        </div>
      )}

      {/* Items summary */}
      <div className="bg-(--color-surface) rounded-(--radius-lg) p-4 mb-4">
        <h3 className="text-xs font-semibold text-(--color-text-muted) uppercase tracking-wider mb-3">
          Detalle del pedido
        </h3>
        <div className="flex flex-col gap-2">
          {order.order_items.map((item) => (
            <div key={item.id} className="flex items-center justify-between">
              <span className="text-sm text-(--color-text-primary)">
                <span className="text-(--color-text-secondary) mr-1">{item.quantity}×</span>
                {item.name}
              </span>
              <span className="text-sm font-medium text-(--color-text-primary)">
                {formatPrice(Number(item.unit_price) * item.quantity)}
              </span>
            </div>
          ))}
          {Number(order.delivery_fee) > 0 && (
            <div className="flex items-center justify-between pt-1">
              <span className="text-sm text-(--color-text-secondary)">Envío</span>
              <span className="text-sm text-(--color-text-secondary)">{formatPrice(Number(order.delivery_fee))}</span>
            </div>
          )}
          <div className="border-t border-(--color-border) mt-1 pt-2 flex justify-between">
            <span className="text-sm font-semibold text-(--color-text-primary)">Total</span>
            <span className="text-sm font-bold text-(--color-primary)">
              {formatPrice(order.total + Number(order.delivery_fee))}
            </span>
          </div>
        </div>
      </div>

      <Link to="/historial" className="block text-center text-sm text-(--color-text-secondary) py-2">
        Ver mis pedidos anteriores
      </Link>
    </div>
  )
}
