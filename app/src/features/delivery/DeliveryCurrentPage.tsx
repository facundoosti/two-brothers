import { useEffect, useRef } from 'react'
import { MapPin, Navigation, Phone, Clock, Package, CheckCircle2, Wifi } from 'lucide-react'
import { cn } from '@/lib/utils'
import MapView from '@/components/MapView'
import { useDeliveryAssignments, useUpdateAssignmentStatus } from '@/api/deliveryAssignments'
import { useCreateDeliveryLocation, useLatestLocation } from '@/api/deliveryLocations'

// Coordenadas del local (Washington 133, Dolores)
const LOCAL_COORDS: [number, number] = [-57.6833, -36.3192]

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-AR', {
    style: 'currency', currency: 'ARS', maximumFractionDigits: 0,
  }).format(n)
}

export default function DeliveryCurrentPage() {
  const { data, isLoading } = useDeliveryAssignments()
  const updateStatus = useUpdateAssignmentStatus()
  const createLocation = useCreateDeliveryLocation()
  const watchIdRef = useRef<number | null>(null)

  const assignment = data?.data.find(
    a => a.status === 'in_transit' || a.status === 'assigned'
  )

  const { data: location } = useLatestLocation(
    assignment?.status === 'in_transit' ? assignment.id : undefined
  )

  // Track GPS position while in_transit and POST each movement to the API
  useEffect(() => {
    if (assignment?.status !== 'in_transit') {
      if (watchIdRef.current !== null) {
        navigator.geolocation.clearWatch(watchIdRef.current)
        watchIdRef.current = null
      }
      return
    }

    if (!navigator.geolocation) return

    watchIdRef.current = navigator.geolocation.watchPosition(
      (pos) => {
        createLocation.mutate({
          delivery_assignment_id: assignment.id,
          latitude: pos.coords.latitude,
          longitude: pos.coords.longitude,
          recorded_at: new Date(pos.timestamp).toISOString(),
        })
      },
      undefined,
      { enableHighAccuracy: true, maximumAge: 0 },
    )

    return () => {
      if (watchIdRef.current !== null) {
        navigator.geolocation.clearWatch(watchIdRef.current)
        watchIdRef.current = null
      }
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [assignment?.status, assignment?.id])

  const deliveryCoords: [number, number] | null = location
    ? [Number(location.longitude), Number(location.latitude)]
    : null

  const mapCenter: [number, number] = deliveryCoords
    ? [(LOCAL_COORDS[0] + deliveryCoords[0]) / 2, (LOCAL_COORDS[1] + deliveryCoords[1]) / 2]
    : LOCAL_COORDS

  function handleStartDelivery() {
    if (!assignment) return
    updateStatus.mutate({ id: assignment.id, status: 'in_transit' })
  }

  function handleConfirmDelivery() {
    if (!assignment) return
    updateStatus.mutate({ id: assignment.id, status: 'delivered' })
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[70vh]">
        <p className="text-sm text-(--color-text-muted)">Cargando...</p>
      </div>
    )
  }

  if (!assignment) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[70vh] px-6 gap-4 text-center">
        <div className="w-16 h-16 rounded-full bg-(--color-surface-elevated) flex items-center justify-center">
          <Package size={28} className="text-(--color-text-muted)" />
        </div>
        <div>
          <h2 className="text-lg font-bold text-(--color-text-primary)">Sin reparto activo</h2>
          <p className="text-sm text-(--color-text-secondary) mt-1">No tenés repartos en curso.</p>
        </div>
      </div>
    )
  }

  const o = assignment.order
  const step = assignment.status
  const gpsActive = step === 'in_transit'

  if (updateStatus.isSuccess && updateStatus.variables?.status === 'delivered') {
    return (
      <div className="flex flex-col items-center justify-center min-h-[70vh] px-6 gap-4 text-center">
        <div className="w-20 h-20 rounded-full bg-(--color-primary-muted) flex items-center justify-center">
          <CheckCircle2 size={40} className="text-(--color-primary)" />
        </div>
        <div>
          <h2 className="text-xl font-bold text-(--color-text-primary)">¡Entrega confirmada!</h2>
          <p className="text-sm text-(--color-text-secondary) mt-1">
            Orden #{String(o.id).padStart(4, '0')} entregada correctamente.
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="flex flex-col max-w-lg mx-auto">
      {/* Map */}
      <div className="relative mx-4 mt-4 rounded-(--radius-lg) overflow-hidden h-52 border border-(--color-border)">
        <MapView
          center={mapCenter}
          zoom={13}
          routeFrom={LOCAL_COORDS}
          routeTo={deliveryCoords ?? LOCAL_COORDS}
          markers={[
            { lngLat: LOCAL_COORDS, kind: 'origin', tooltip: 'Two Brothers' },
            ...(deliveryCoords ? [{ lngLat: deliveryCoords, kind: 'delivery' as const, tooltip: 'Tu posición' }] : []),
          ]}
          className="absolute inset-0"
        />
        {gpsActive && (
          <div className="absolute top-3 right-3 flex items-center gap-1.5 bg-black/60 backdrop-blur-sm border border-(--color-primary)/30 rounded-full px-2.5 py-1 pointer-events-none">
            <Wifi size={11} className="text-(--color-primary) animate-pulse" />
            <span className="text-[10px] text-(--color-primary) font-medium">GPS activo</span>
          </div>
        )}
      </div>

      {/* Order panel */}
      <div className="px-4 mt-4 flex flex-col gap-3">
        {/* Status + order number */}
        <div className="bg-(--color-surface) rounded-(--radius-lg) p-4">
          <div className="flex items-center justify-between mb-3">
            <div>
              <span className="font-mono font-semibold text-(--color-text-primary)">
                #{String(o.id).padStart(4, '0')}
              </span>
              <span className={cn(
                'ml-2 badge-sm',
                step === 'in_transit'
                  ? 'bg-(--color-primary)/15 text-(--color-primary)'
                  : 'bg-(--color-accent)/15 text-(--color-accent)',
              )}>
                {step === 'in_transit' ? 'En camino' : 'Listo para salir'}
              </span>
            </div>
            {assignment.assigned_at && (
              <span className="text-xs text-(--color-text-muted)">
                {new Date(assignment.assigned_at).toLocaleTimeString('es-AR', { hour: '2-digit', minute: '2-digit' })} hs
              </span>
            )}
          </div>

          {/* Customer */}
          <div className="flex items-center justify-between py-2 border-t border-(--color-border)">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-full bg-(--color-surface-elevated) flex items-center justify-center text-sm font-bold text-(--color-text-secondary)">
                {o.user.name.charAt(0)}
              </div>
              <p className="text-sm font-medium text-(--color-text-primary)">{o.user.name}</p>
            </div>
            <div className="w-8 h-8 rounded-full bg-(--color-surface-elevated) flex items-center justify-center text-(--color-text-muted)">
              <Phone size={15} />
            </div>
          </div>
        </div>

        {/* Address */}
        {o.delivery_address && (
          <div className="bg-(--color-surface) rounded-(--radius-lg) p-4">
            <div className="flex items-start gap-2">
              <MapPin size={15} className="text-(--color-accent) shrink-0 mt-0.5" />
              <p className="text-sm font-medium text-(--color-text-primary)">{o.delivery_address}</p>
            </div>
          </div>
        )}

        {/* Items */}
        <div className="bg-(--color-surface) rounded-(--radius-lg) p-4">
          <h3 className="section-label mb-3">Contenido del pedido</h3>
          <div className="flex flex-col gap-1.5">
            {o.order_items.map((item) => (
              <div key={item.id} className="flex justify-between">
                <span className="text-sm text-(--color-text-primary)">
                  <span className="text-(--color-text-secondary) mr-1">{item.quantity}×</span>
                  {item.name}
                </span>
                <span className="text-sm text-(--color-text-secondary)">
                  {formatPrice(Number(item.unit_price) * item.quantity)}
                </span>
              </div>
            ))}
            <div className="border-t border-(--color-border) mt-1.5 pt-1.5 flex justify-between">
              <span className="text-sm font-semibold text-(--color-text-primary)">Total</span>
              <span className="text-sm font-bold text-(--color-primary)">{formatPrice(o.total)}</span>
            </div>
          </div>

          <div className="mt-3 pt-3 border-t border-(--color-border) flex items-center gap-2">
            {o.payment_method === 'cash' ? (
              <>
                <Package size={13} className="text-(--color-accent)" />
                <span className="text-xs text-(--color-accent) font-medium">
                  Cobrar en efectivo: {formatPrice(o.total)}
                </span>
              </>
            ) : (
              <>
                <Clock size={13} className="text-(--color-text-muted)" />
                <span className="text-xs text-(--color-text-muted)">Pago ya transferido — no cobrar</span>
              </>
            )}
          </div>
        </div>

        {/* CTA */}
        {step === 'assigned' ? (
          <button
            onClick={handleStartDelivery}
            disabled={updateStatus.isPending}
            className="w-full bg-(--color-primary) text-(--color-background) font-semibold py-4 rounded-(--radius-pill) flex items-center justify-center gap-2 text-base disabled:opacity-50"
          >
            <Navigation size={18} />
            Salir a entregar
          </button>
        ) : (
          <button
            onClick={handleConfirmDelivery}
            disabled={updateStatus.isPending}
            className="w-full bg-(--color-primary) text-(--color-background) font-semibold py-4 rounded-(--radius-pill) flex items-center justify-center gap-2 text-base disabled:opacity-50"
          >
            <CheckCircle2 size={18} />
            Confirmar entrega
          </button>
        )}
      </div>
    </div>
  )
}
