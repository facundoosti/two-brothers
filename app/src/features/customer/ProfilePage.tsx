import { useState } from 'react'
import { MapPin, Pencil, Trash2, Check, X } from 'lucide-react'
import { useAuthStore } from '@/store/authStore'
import { useUpdateProfile } from '@/api/users'
import { AddressSearchInput } from '@/components/AddressSearchInput'

export default function ProfilePage() {
  const { user } = useAuthStore()
  const updateProfile = useUpdateProfile()

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
      { onSuccess: () => setEditing(false) },
    )
  }

  function handleRemove() {
    updateProfile.mutate({ default_address: null })
  }

  if (!user) return null

  const initials = user.name
    .split(' ')
    .slice(0, 2)
    .map((w) => w[0])
    .join('')
    .toUpperCase()

  return (
    <div className="max-w-lg mx-auto px-4 pt-6 pb-12 flex flex-col gap-6">
      {/* User card */}
      <div className="bg-(--color-surface) rounded-(--radius-lg) p-5 flex items-center gap-4">
        {user.avatar_url ? (
          <img
            src={user.avatar_url}
            alt={user.name}
            className="w-14 h-14 rounded-full object-cover shrink-0"
          />
        ) : (
          <div className="w-14 h-14 rounded-full bg-(--color-primary-muted) flex items-center justify-center shrink-0">
            <span className="text-lg font-bold text-(--color-primary)">{initials}</span>
          </div>
        )}
        <div className="min-w-0">
          <p className="font-semibold text-(--color-text-primary) truncate">{user.name}</p>
          <p className="text-sm text-(--color-text-secondary) truncate">{user.email}</p>
        </div>
      </div>

      {/* Default address */}
      <div>
        <h2 className="text-xs font-semibold text-(--color-text-muted) uppercase tracking-wider mb-3">
          Dirección por defecto
        </h2>

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
                className="flex-1 flex items-center justify-center gap-2 bg-(--color-primary) text-(--color-background) font-semibold py-2.5 rounded-(--radius-pill) text-sm disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {updateProfile.isPending ? (
                  <span className="animate-spin rounded-full border-2 border-(--color-background) border-t-transparent w-4 h-4" />
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
            {updateProfile.isError && (
              <p className="text-xs text-red-400 text-center">{updateProfile.error.message}</p>
            )}
          </div>
        ) : user.default_address ? (
          <div className="bg-(--color-surface) rounded-(--radius-lg) p-4">
            <div className="flex items-start gap-3">
              <MapPin size={16} className="text-(--color-primary) shrink-0 mt-0.5" />
              <p className="text-sm text-(--color-text-primary) flex-1 leading-snug">
                {user.default_address}
              </p>
            </div>
            <div className="flex gap-2 mt-4">
              <button
                onClick={handleStartEdit}
                className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-(--radius-pill) border border-(--color-border) text-(--color-text-secondary) text-sm hover:border-(--color-primary)/50 hover:text-(--color-primary) transition-colors"
              >
                <Pencil size={13} />
                Editar
              </button>
              <button
                onClick={handleRemove}
                disabled={updateProfile.isPending}
                className="flex items-center justify-center gap-1.5 px-4 py-2 rounded-(--radius-pill) border border-(--color-border) text-(--color-destructive) text-sm opacity-70 hover:opacity-100 disabled:opacity-40 disabled:cursor-not-allowed transition-opacity"
              >
                {updateProfile.isPending ? (
                  <span className="animate-spin rounded-full border-2 border-current border-t-transparent w-3.5 h-3.5" />
                ) : (
                  <Trash2 size={13} />
                )}
                Quitar
              </button>
            </div>
          </div>
        ) : (
          <div className="bg-(--color-surface) rounded-(--radius-lg) p-4 flex flex-col items-center gap-3 py-7">
            <div className="w-10 h-10 rounded-full bg-(--color-surface-elevated) flex items-center justify-center">
              <MapPin size={18} className="text-(--color-text-muted)" />
            </div>
            <p className="text-sm text-(--color-text-secondary) text-center">
              No tenés una dirección guardada
            </p>
            <button
              onClick={handleStartEdit}
              className="bg-(--color-primary) text-(--color-background) font-semibold px-5 py-2 rounded-(--radius-pill) text-sm"
            >
              Agregar dirección
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
