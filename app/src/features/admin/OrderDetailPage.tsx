import { useState } from 'react'
import { ArrowLeft, X, MapPin, CreditCard, CheckCircle2, ChevronDown } from 'lucide-react'
import { Link, useParams } from 'react-router'
import AdminTopbar from './components/AdminTopbar'
import { ORDER_STATUS_LABEL, ORDER_STATUS_CLASSES } from '@/lib/status'
import { useOrder, useUpdateOrderStatus, useCancelOrder, useConfirmPayment } from '@/api/orders'
import { useUsers } from '@/api/users'
import { useCreateDeliveryAssignment } from '@/api/deliveryAssignments'
import MapView from '@/components/MapView'

const LOCAL_COORDS: [number, number] = [-57.6833, -36.3192]

const PAYMENT_METHOD_LABEL = { cash: 'Efectivo', transfer: 'Transferencia' }
const MODALITY_LABEL = { delivery: 'Delivery', pickup: 'Retiro en local' }

const NEXT_STATUS_DELIVERY: Record<string, string> = {
  confirmed: 'preparing',
  preparing: 'ready',
  ready: 'delivering',
}

const NEXT_STATUS_PICKUP: Record<string, string> = {
  confirmed: 'preparing',
  preparing: 'ready',
  ready: 'delivered',
}

const NEXT_STATUS_LABEL: Record<string, string> = {
  confirmed: 'Marcar en preparación',
  preparing: 'Marcar como Lista',
  ready_delivery: 'Marcar en camino',
  ready_pickup: 'Marcar como entregada',
}

export default function OrderDetailPage() {
  const { id } = useParams()
  const { data: order, isLoading } = useOrder(id!)
  const { data: deliveryUsers } = useUsers({ role: 'delivery' })
  const updateStatus = useUpdateOrderStatus()
  const cancelOrder = useCancelOrder()
  const confirmPayment = useConfirmPayment()
  const createAssignment = useCreateDeliveryAssignment()

  const [selectedDeliveryUserId, setSelectedDeliveryUserId] = useState<string>('')

  if (isLoading || !order) {
    return (
      <>
        <AdminTopbar title="Orden" subtitle="Cargando..." />
        <div className="flex-1 flex items-center justify-center">
          <p className="text-sm text-(--color-text-muted)">Cargando orden...</p>
        </div>
      </>
    )
  }

  const canCancel = order.status === 'pending_payment' || order.status === 'confirmed'
  const nextStatusMap = order.modality === 'pickup' ? NEXT_STATUS_PICKUP : NEXT_STATUS_DELIVERY
  const nextStatus = nextStatusMap[order.status]
  const nextStatusLabelKey = order.status === 'ready'
    ? (order.modality === 'pickup' ? 'ready_pickup' : 'ready_delivery')
    : order.status
  const nextStatusLabel = NEXT_STATUS_LABEL[nextStatusLabelKey]

  function handleNextStatus() {
    if (!nextStatus) return
    if (order.status === 'pending_payment') {
      confirmPayment.mutate(order.id)
    } else {
      updateStatus.mutate({ id: order.id, status: nextStatus })
    }
  }

  function handleCancel() {
    if (!confirm('¿Cancelar esta orden?')) return
    cancelOrder.mutate({ id: order.id })
  }

  function handleAssignDelivery() {
    if (!selectedDeliveryUserId) return
    createAssignment.mutate({ order_id: order.id, user_id: Number(selectedDeliveryUserId) })
  }

  const isBusy = updateStatus.isPending || cancelOrder.isPending || confirmPayment.isPending || createAssignment.isPending

  return (
    <>
      <AdminTopbar
        title={`Orden #${String(order.id).padStart(4, '0')}`}
        subtitle={
          <span className={`badge ${ORDER_STATUS_CLASSES[order.status]}`}>
            {ORDER_STATUS_LABEL[order.status]}
          </span>
        }
        actions={
          <div className="flex items-center gap-2">
            <Link to="/admin/ordenes" className="flex items-center gap-1.5 px-3 py-1.5 text-sm text-(--color-text-secondary) hover:text-(--color-text-primary) transition-colors">
              <ArrowLeft size={14} /> Órdenes
            </Link>
            {canCancel && (
              <button
                onClick={handleCancel}
                disabled={isBusy}
                className="btn-destructive"
              >
                <X size={14} /> Cancelar orden
              </button>
            )}
          </div>
        }
      />

      <div className="flex-1 p-8 overflow-y-auto">
        <div className="grid grid-cols-[1fr_320px] gap-5">
          {/* Left column */}
          <div className="flex flex-col gap-5">
            {/* Items */}
            <div className="card">
              <div className="flex items-center justify-between px-6 py-4 border-b border-(--color-border)">
                <h2 className="font-semibold text-(--color-text-primary)">Ítems del pedido</h2>
                <span className="text-xs text-(--color-text-secondary)">
                  {order.order_items.length} ítem · ${Number(order.total).toLocaleString('es-AR')}
                </span>
              </div>
              <div className="divide-y divide-(--color-border)">
                {order.order_items.map((item) => (
                  <div key={item.id} className="flex items-center gap-4 px-6 py-4">
                    <div className="w-10 h-10 rounded-lg bg-(--color-surface-elevated) border border-(--color-border) flex items-center justify-center text-lg">
                      🍗
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-medium text-(--color-text-primary)">{item.name}</p>
                    </div>
                    <div className="flex items-center gap-4 text-sm">
                      <span className="text-(--color-text-secondary)">x{item.quantity}</span>
                      <span className="font-medium text-(--color-text-primary)">
                        ${(item.quantity * Number(item.unit_price)).toLocaleString('es-AR')}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Status timeline */}
            <div className="card">
              <div className="px-6 py-4 border-b border-(--color-border)">
                <h2 className="font-semibold text-(--color-text-primary)">Estado actual</h2>
              </div>
              <div className="px-6 py-4">
                <p className="text-sm text-(--color-text-secondary)">
                  Creada el{' '}
                  <span className="text-(--color-text-primary)">
                    {new Date(order.created_at).toLocaleString('es-AR', {
                      day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit'
                    })}
                  </span>
                </p>
              </div>
            </div>

            {/* Delivery map */}
            {order.modality === 'delivery' && order.latitude && order.longitude && (() => {
              const dest: [number, number] = [Number(order.longitude), Number(order.latitude)]
              return (
                <div className="card overflow-hidden">
                  <div className="flex items-center justify-between px-6 py-4 border-b border-(--color-border)">
                    <h2 className="font-semibold text-(--color-text-primary)">Dirección de entrega</h2>
                    {order.delivery_address && (
                      <span className="flex items-center gap-1.5 text-xs text-(--color-text-secondary)">
                        <MapPin size={11} />
                        {order.delivery_address}
                      </span>
                    )}
                  </div>
                  <div className="relative h-96">
                    <MapView
                      center={[(LOCAL_COORDS[0] + dest[0]) / 2, (LOCAL_COORDS[1] + dest[1]) / 2]}
                      zoom={13}
                      routeFrom={LOCAL_COORDS}
                      routeTo={dest}
                      markers={[
                        { lngLat: LOCAL_COORDS, kind: 'origin', tooltip: 'Two Brothers — Washington 133' },
                        { lngLat: dest, kind: 'destination', tooltip: order.delivery_address ?? 'Destino' },
                      ]}
                      className="absolute inset-0"
                    />
                  </div>
                </div>
              )
            })()}
          </div>

          {/* Right column */}
          <div className="flex flex-col gap-5">
            {/* Customer */}
            <div className="card">
              <div className="card-header">
                <h2 className="font-semibold text-(--color-text-primary)">Cliente</h2>
              </div>
              <div className="card-body flex flex-col gap-3">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-full bg-(--color-primary)/20 flex items-center justify-center text-sm font-semibold text-(--color-primary)">
                    {order.user.name.split(' ').map(n => n[0]).join('').slice(0, 2)}
                  </div>
                  <p className="text-sm font-medium text-(--color-text-primary)">{order.user.name}</p>
                </div>
                {order.delivery_address && (
                  <div className="flex items-start gap-2 text-xs text-(--color-text-secondary)">
                    <MapPin size={12} className="shrink-0 mt-0.5" />
                    <span>{order.delivery_address}</span>
                  </div>
                )}
                <span className="badge w-fit bg-(--color-primary)/15 text-(--color-primary)">
                  {MODALITY_LABEL[order.modality]}
                </span>
              </div>
            </div>

            {/* Payment */}
            <div className="card">
              <div className="card-header">
                <h2 className="font-semibold text-(--color-text-primary)">Pago</h2>
              </div>
              <div className="card-body flex flex-col gap-2.5 text-sm">
                <div className="flex justify-between">
                  <span className="text-(--color-text-secondary)">Subtotal</span>
                  <span className="font-medium text-(--color-text-primary)">${Number(order.total).toLocaleString('es-AR')}</span>
                </div>
                {Number(order.delivery_fee) > 0 && (
                  <div className="flex justify-between">
                    <span className="text-(--color-text-secondary)">Envío</span>
                    <span className="font-medium text-(--color-text-primary)">${Number(order.delivery_fee).toLocaleString('es-AR')}</span>
                  </div>
                )}
                <div className="flex justify-between pt-1 border-t border-(--color-border)">
                  <span className="font-semibold text-(--color-text-primary)">Total</span>
                  <span className="font-bold text-(--color-text-primary)">${(Number(order.total) + Number(order.delivery_fee)).toLocaleString('es-AR')}</span>
                </div>
                <div className="flex justify-between items-center pt-1 border-t border-(--color-border)">
                  <span className="text-(--color-text-secondary)">Método</span>
                  <div className="flex items-center gap-1.5 text-(--color-text-primary)">
                    <CreditCard size={12} />
                    <span className="text-xs">{PAYMENT_METHOD_LABEL[order.payment_method]}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Actions */}
            <div className="card">
              <div className="card-header">
                <h2 className="font-semibold text-(--color-text-primary)">Acciones</h2>
              </div>
              <div className="card-body flex flex-col gap-3">
                {order.status === 'pending_payment' && (
                  <button
                    onClick={() => confirmPayment.mutate(order.id)}
                    disabled={isBusy}
                    className="btn-primary w-full"
                  >
                    <CheckCircle2 size={16} /> Confirmar pago
                  </button>
                )}

                {nextStatus && order.status !== 'pending_payment' && (
                  <button
                    onClick={handleNextStatus}
                    disabled={isBusy}
                    className="btn-primary w-full"
                  >
                    <CheckCircle2 size={16} /> {nextStatusLabel}
                  </button>
                )}

                {order.status === 'delivering' && order.delivery_assignment_id && (
                  <Link
                    to={`/admin/trackeo/${order.delivery_assignment_id}`}
                    className="btn-ghost w-full"
                  >
                    <MapPin size={16} /> Ver en mapa
                  </Link>
                )}

                {(order.status === 'ready' || order.status === 'confirmed' || order.status === 'preparing') &&
                  order.modality === 'delivery' &&
                  !order.delivery_assignment_id && (
                    <div className="flex flex-col gap-1.5">
                      <label className="text-xs text-(--color-text-secondary)">Asignar repartidor</label>
                      <div className="relative">
                        <select
                          value={selectedDeliveryUserId}
                          onChange={e => setSelectedDeliveryUserId(e.target.value)}
                          className="form-input w-full appearance-none pr-8 cursor-pointer"
                        >
                          <option value="">Seleccionar repartidor...</option>
                          {(deliveryUsers?.data ?? []).map(u => (
                            <option key={u.id} value={u.id}>{u.name}</option>
                          ))}
                        </select>
                        <ChevronDown size={14} className="absolute right-2.5 top-1/2 -translate-y-1/2 text-(--color-text-muted) pointer-events-none" />
                      </div>
                      {selectedDeliveryUserId && (
                        <button
                          onClick={handleAssignDelivery}
                          disabled={isBusy}
                          className="w-full py-2 rounded-lg bg-(--color-primary)/15 border border-(--color-primary)/30 text-sm font-medium text-(--color-primary) hover:bg-(--color-primary)/25 transition-colors disabled:opacity-50"
                        >
                          Confirmar asignación
                        </button>
                      )}
                    </div>
                  )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  )
}
