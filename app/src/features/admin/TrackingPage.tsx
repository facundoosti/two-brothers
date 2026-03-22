import { ArrowLeft, CheckCircle2, MapPin } from 'lucide-react'
import { Link, useParams } from 'react-router'
import AdminTopbar from './components/AdminTopbar'
import { ORDER_STATUS_LABEL, ORDER_STATUS_CLASSES } from '@/lib/status'
import MapView from '@/components/MapView'
import { useDeliveryAssignments, useUpdateAssignmentStatus } from '@/api/deliveryAssignments'
import { useLatestLocation } from '@/api/deliveryLocations'

// Coordenadas del local (Washington 133, Dolores)
const LOCAL_COORDS: [number, number] = [-57.6833, -36.3192]

export default function TrackingPage() {
  const { id } = useParams()
  const { data: assignmentsData } = useDeliveryAssignments()
  const updateStatus = useUpdateAssignmentStatus()

  const assignment = assignmentsData?.data.find(a => String(a.id) === id)
  const { data: location } = useLatestLocation(assignment?.id)

  const deliveryCoords: [number, number] | null = location
    ? [Number(location.longitude), Number(location.latitude)]
    : null

  const order = assignment?.order
  const destinationCoords: [number, number] | null =
    order?.latitude && order?.longitude
      ? [Number(order.longitude), Number(order.latitude)]
      : null

  const mapCenter: [number, number] = deliveryCoords
    ? [(LOCAL_COORDS[0] + deliveryCoords[0]) / 2, (LOCAL_COORDS[1] + deliveryCoords[1]) / 2]
    : LOCAL_COORDS

  const orderStatus = assignment?.order.status ?? 'delivering'

  function handleConfirmDelivery() {
    if (!assignment) return
    updateStatus.mutate({ id: assignment.id, status: 'delivered' })
  }

  if (!assignment && assignmentsData) {
    return (
      <>
        <AdminTopbar title="Trackeo" subtitle="Reparto no encontrado" />
        <div className="flex-1 flex items-center justify-center">
          <p className="text-sm text-(--color-text-muted)">No se encontró el reparto #{id}</p>
        </div>
      </>
    )
  }

  return (
    <>
      <AdminTopbar
        title={`Trackeo — Orden #${assignment ? String(assignment.order.id).padStart(4, '0') : '...'}`}
        subtitle={
          <span className={`badge ${ORDER_STATUS_CLASSES[orderStatus as keyof typeof ORDER_STATUS_CLASSES] ?? ''}`}>
            {ORDER_STATUS_LABEL[orderStatus as keyof typeof ORDER_STATUS_LABEL] ?? orderStatus}
          </span>
        }
        actions={
          <div className="flex items-center gap-2">
            <Link to="/admin/ordenes" className="flex items-center gap-1.5 px-3 py-1.5 text-sm text-(--color-text-secondary) hover:text-(--color-text-primary) transition-colors">
              <ArrowLeft size={14} /> Órdenes
            </Link>
          </div>
        }
      />

      <div className="flex-1 overflow-hidden flex">
        {/* Map */}
        <div className="flex-1 relative border-r border-(--color-border) overflow-hidden">
          <MapView
            center={mapCenter}
            zoom={13}
            routeFrom={LOCAL_COORDS}
            routeTo={deliveryCoords ?? LOCAL_COORDS}
            markers={[
              { lngLat: LOCAL_COORDS, kind: 'origin', tooltip: 'Two Brothers — Washington 133' },
              ...(deliveryCoords ? [{ lngLat: deliveryCoords, kind: 'delivery' as const, tooltip: assignment?.user_name ?? 'Repartidor' }] : []),
              ...(destinationCoords ? [{ lngLat: destinationCoords, kind: 'destination' as const, tooltip: order?.delivery_address ?? 'Destino' }] : []),
            ]}
            className="absolute inset-0"
          />
          <div className="absolute top-3 left-3 flex items-center gap-1.5 bg-black/60 backdrop-blur-sm border border-(--color-primary)/30 rounded-full px-2.5 py-1 pointer-events-none">
            <span className="w-1.5 h-1.5 rounded-full bg-(--color-primary) animate-pulse" />
            <span className="text-[11px] text-(--color-primary) font-medium">En vivo</span>
          </div>
          <div className="absolute bottom-3 left-3 flex flex-col gap-1.5 bg-black/60 backdrop-blur-sm border border-(--color-border) rounded-xl px-3 py-2 pointer-events-none">
            {[
              { color: 'bg-[#40C97F]', label: 'Local' },
              { color: 'bg-[#40C97F] ring-2 ring-[#40C97F]/30', label: assignment?.user_name ?? 'Repartidor' },
              ...(destinationCoords ? [{ color: 'bg-[#9B5CF6]', label: 'Destino' }] : []),
            ].map((item) => (
              <div key={item.label} className="flex items-center gap-2">
                <span className={`w-2.5 h-2.5 rounded-full shrink-0 ${item.color}`} />
                <span className="text-[11px] text-(--color-text-secondary)">{item.label}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Info panel */}
        <aside className="w-[320px] shrink-0 flex flex-col gap-4 p-5 overflow-y-auto">
          {/* Delivery person */}
          <div className="card p-4 flex flex-col gap-3">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-semibold text-(--color-text-primary)">Repartidor</h3>
              <span className="badge bg-(--color-primary)/15 text-(--color-primary)">En vivo</span>
            </div>
            <div className="flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-full bg-(--color-surface-elevated) border border-(--color-border) flex items-center justify-center text-sm font-semibold text-(--color-text-secondary)">
                {(assignment?.user_name ?? '?').split(' ').map(n => n[0]).join('').slice(0, 2)}
              </div>
              <p className="text-sm font-medium text-(--color-text-primary)">{assignment?.user_name ?? '—'}</p>
            </div>
          </div>

          {/* Order info */}
          {assignment && (
            <div className="card p-4 flex flex-col gap-2.5">
              <h3 className="text-sm font-semibold text-(--color-text-primary)">
                Orden #{String(assignment.order.id).padStart(4, '0')}
              </h3>
              {assignment.order.delivery_address && (
                <p className="text-xs text-(--color-text-secondary) flex items-start gap-1.5">
                  <MapPin size={11} className="shrink-0 mt-0.5 text-(--color-text-muted)" />
                  {assignment.order.delivery_address}
                </p>
              )}
              <div className="pt-1 text-xs text-(--color-text-secondary)">
                Cliente: <span className="text-(--color-text-primary)">{assignment.order.user.name}</span>
              </div>
            </div>
          )}

          {/* Items */}
          {assignment && assignment.order.order_items.length > 0 && (
            <div className="card p-4">
              <h3 className="text-sm font-semibold text-(--color-text-primary) mb-2">Ítems</h3>
              <div className="flex flex-col gap-1.5">
                {assignment.order.order_items.map((item) => (
                  <div key={item.id} className="flex justify-between text-xs">
                    <span className="text-(--color-text-secondary)">{item.quantity}× {item.name}</span>
                    <span className="text-(--color-text-primary)">${(item.quantity * Number(item.unit_price)).toLocaleString('es-AR')}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Confirm delivery */}
          {assignment?.status === 'in_transit' && (
            <button
              onClick={handleConfirmDelivery}
              disabled={updateStatus.isPending}
              className="btn-primary w-full"
            >
              <CheckCircle2 size={16} /> Confirmar entrega
            </button>
          )}
          {assignment?.status === 'delivered' && (
            <p className="text-center text-sm text-(--color-primary) font-medium">✓ Entregado</p>
          )}
        </aside>
      </div>
    </>
  )
}
