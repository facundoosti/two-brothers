import { useState } from 'react'
import { Link, useNavigate } from 'react-router'
import { MapPin, Pencil, Trash2, Check, X, ChevronRight, LogOut } from 'lucide-react'
import { sileo } from 'sileo'
import { useAuthStore } from '@/store/authStore'
import { useUpdateProfile } from '@/api/users'
import { useOrders } from '@/api/orders'
import { AddressSearchInput } from '@/components/AddressSearchInput'
import { ORDER_STATUS_LABEL, ORDER_STATUS_CLASSES } from '@/lib/status'
import { cn } from '@/lib/utils'

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

export default function ProfilePage() {
  const { user, clearAuth } = useAuthStore()
  const updateProfile = useUpdateProfile()
  const { data: ordersData } = useOrders()
  const navigate = useNavigate()

  const [editing, setEditing] = useState(false)
  const [draftAddress, setDraftAddress] = useState('')

  function handleStartEdit() {
    setDraftAddress(user?.default_address ?? '')
    setEditing(true)
  }

  function handleCancel() {
    setEditing(false)
    setDraftAddress('')
  }

  function handleSave() {
    if (!draftAddress.trim()) return
    updateProfile.mutate(
      { default_address: draftAddress.trim() },
      {
        onSuccess: () => {
          setEditing(false)
          sileo.success({ title: 'Dirección guardada' })
        },
        onError: (err) => sileo.error({ title: err.message }),
      },
    )
  }

  function handleRemove() {
    updateProfile.mutate(
      { default_address: null },
      { onSuccess: () => sileo.success({ title: 'Dirección eliminada' }) },
    )
  }

  function handleLogout() {
    clearAuth()
    navigate('/login', { replace: true })
  }

  if (!user) return null

  const initials = user.name
    .split(' ')
    .slice(0, 2)
    .map((w) => w[0])
    .join('')
    .toUpperCase()

  const recentOrders = (ordersData?.data ?? []).slice(0, 4)

  return (
    <div className="max-w-lg mx-auto px-5 pt-6 pb-32">
      {/* Profile header */}
      <header className="flex flex-col items-center mb-10">
        <div className="relative mb-4">
          {user.avatar_url ? (
            <img
              src={user.avatar_url}
              alt={user.name}
              className="w-28 h-28 rounded-full object-cover border-4 border-(--color-surface) shadow-xl"
            />
          ) : (
            <div className="w-28 h-28 rounded-full bg-(--color-primary-muted) flex items-center justify-center border-4 border-(--color-surface) shadow-xl">
              <span className="text-3xl font-bold text-(--color-primary)">{initials}</span>
            </div>
          )}
          <div className="absolute bottom-1 right-1 bg-(--color-primary) text-[#00391d] rounded-full p-1.5 shadow-lg">
            <Check size={13} strokeWidth={3} />
          </div>
        </div>

        <h1 className="text-2xl font-bold tracking-tight text-(--color-text-primary) mb-1">
          {user.name}
        </h1>
        <p className="text-(--color-text-secondary) text-xs tracking-wider font-mono mb-3">
          {user.email}
        </p>
        <span className="bg-(--color-surface-elevated) text-(--color-primary) px-4 py-1 rounded-full text-[10px] font-bold tracking-[0.2em] uppercase">
          Cliente
        </span>
      </header>

      {/* Delivery address */}
      <section className="mb-8">
        <div className="flex items-center justify-between mb-3 px-1">
          <h2 className="text-[10px] font-bold uppercase tracking-widest text-(--color-text-secondary)">
            Dirección de entrega
          </h2>
          {!editing && user.default_address && (
            <button
              onClick={handleStartEdit}
              className="text-xs font-bold text-(--color-primary) hover:opacity-80 transition-opacity uppercase tracking-tight"
            >
              Editar
            </button>
          )}
        </div>

        {editing ? (
          <div className="bg-(--color-surface) rounded-(--radius-lg) p-4 flex flex-col gap-3">
            <AddressSearchInput
              value={draftAddress}
              onChange={setDraftAddress}
              placeholder="Ingresá tu dirección en Dolores"
            />
            <div className="flex gap-2">
              <button
                onClick={handleSave}
                disabled={!draftAddress.trim() || updateProfile.isPending}
                className="flex-1 flex items-center justify-center gap-2 bg-(--color-primary) text-[#00391d] font-bold py-2.5 rounded-(--radius-pill) text-sm disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {updateProfile.isPending ? (
                  <span className="animate-spin rounded-full border-2 border-[#00391d]/30 border-t-[#00391d] w-4 h-4" />
                ) : (
                  <>
                    <Check size={15} />
                    Guardar
                  </>
                )}
              </button>
              <button
                onClick={handleCancel}
                disabled={updateProfile.isPending}
                className="flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-(--radius-pill) border border-(--color-border) text-(--color-text-secondary) text-sm"
              >
                <X size={15} />
                Cancelar
              </button>
            </div>
          </div>
        ) : user.default_address ? (
          <div className="bg-(--color-surface) rounded-(--radius-lg) p-5 flex items-start gap-4">
            <div className="bg-(--color-surface-elevated) p-2.5 rounded-full text-(--color-primary) shrink-0">
              <MapPin size={18} />
            </div>
            <div className="flex-1 min-w-0">
              <p className="font-semibold text-(--color-text-primary) text-sm mb-1">
                Dirección guardada
              </p>
              <p className="text-(--color-text-secondary) text-sm leading-snug">
                {user.default_address}
              </p>
              <button
                onClick={handleRemove}
                disabled={updateProfile.isPending}
                className="flex items-center gap-1.5 mt-3 text-xs text-(--color-destructive) opacity-70 hover:opacity-100 disabled:opacity-40 transition-opacity"
              >
                {updateProfile.isPending ? (
                  <span className="animate-spin rounded-full border-2 border-current border-t-transparent w-3 h-3" />
                ) : (
                  <Trash2 size={12} />
                )}
                Quitar
              </button>
            </div>
          </div>
        ) : (
          <div className="bg-(--color-surface) rounded-(--radius-lg) p-5 flex flex-col items-center gap-3 py-8">
            <div className="w-11 h-11 rounded-full bg-(--color-surface-elevated) flex items-center justify-center">
              <MapPin size={20} className="text-(--color-text-secondary)" />
            </div>
            <p className="text-sm text-(--color-text-secondary) text-center">
              No tenés una dirección guardada
            </p>
            <button
              onClick={handleStartEdit}
              className="bg-(--color-primary) text-[#00391d] font-bold px-6 py-2.5 rounded-(--radius-pill) text-sm"
            >
              Agregar dirección
            </button>
          </div>
        )}
      </section>

      {/* Recent orders */}
      <section className="mb-10">
        <div className="flex items-center justify-between mb-3 px-1">
          <h2 className="text-[10px] font-bold uppercase tracking-widest text-(--color-text-secondary)">
            Mis pedidos
          </h2>
          <Link
            to="/historial"
            className="text-xs font-bold text-(--color-primary) hover:opacity-80 transition-opacity uppercase tracking-tight"
          >
            Ver todos
          </Link>
        </div>

        {recentOrders.length === 0 ? (
          <div className="bg-(--color-surface) rounded-(--radius-lg) p-5 text-center">
            <p className="text-sm text-(--color-text-secondary)">
              Todavía no hiciste ningún pedido
            </p>
            <Link
              to="/"
              className="inline-block mt-3 text-sm font-bold text-(--color-primary)"
            >
              Ver menú →
            </Link>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {recentOrders.map((order) => (
              <Link
                key={order.id}
                to={`/pedido/${order.id}`}
                className="bg-(--color-surface) rounded-(--radius-lg) p-4 flex items-center justify-between transition-transform active:scale-[0.98]"
              >
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="font-mono text-xs font-semibold text-(--color-text-secondary)">
                      #{String(order.id).padStart(5, '0')}
                    </span>
                    <span
                      className={cn(
                        'text-[10px] px-2 py-0.5 rounded-full font-bold uppercase tracking-tight',
                        ORDER_STATUS_CLASSES[order.status],
                      )}
                    >
                      {ORDER_STATUS_LABEL[order.status]}
                    </span>
                  </div>
                  <p className="text-sm font-semibold text-(--color-text-primary) truncate mb-1">
                    {order.order_items.map((i) => i.name).join(', ')}
                  </p>
                  <p className="text-xs text-(--color-text-secondary)">
                    {formatDate(order.created_at)}
                  </p>
                </div>
                <div className="flex flex-col items-end gap-1 shrink-0 ml-3">
                  <span className="font-mono font-bold text-(--color-primary) text-sm">
                    {formatPrice(order.total)}
                  </span>
                  <ChevronRight size={14} className="text-(--color-text-secondary)" />
                </div>
              </Link>
            ))}
          </div>
        )}
      </section>

      {/* Logout */}
      <div className="flex justify-center">
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 px-8 py-4 rounded-full text-(--color-destructive) font-bold uppercase tracking-[0.2em] text-xs hover:bg-(--color-destructive)/10 transition-colors duration-300"
        >
          <LogOut size={18} />
          Cerrar sesión
        </button>
      </div>
    </div>
  )
}
