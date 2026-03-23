import { useState } from 'react'
import { Link } from 'react-router'
import { Plus, Minus, ShoppingCart } from 'lucide-react'
import { useCartStore } from '@/store/cartStore'
import { useCategories } from '@/api/categories'
import { useStoreStatus } from '@/api/storeStatus'
import type { MenuItem } from '@/types/orders'

const DAY_NAMES = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado']

function nextOpeningLabel(openDays: number[], openingTime: string): string {
  const today = new Date().getDay()
  const sorted = [...openDays].sort((a, b) => a - b)
  const next = sorted.find((d) => d > today) ?? sorted[0]
  return `Abrimos el ${DAY_NAMES[next]} a las ${openingTime}`
}

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-AR', {
    style: 'currency', currency: 'ARS', maximumFractionDigits: 0,
  }).format(n)
}

export default function MenuPage() {
  const { data: categories, isLoading, isError } = useCategories()
  const { data: status } = useStoreStatus()
  const { items, addItem, setQuantity } = useCartStore()

  const firstCategoryId = categories?.[0]?.id
  const [activeCategory, setActiveCategory] = useState<number | undefined>(undefined)

  const activeCategoryId = activeCategory ?? firstCategoryId
  const activeItems = categories?.find((c) => c.id === activeCategoryId)?.menu_items ?? []

  const totalItems = items.reduce((sum, i) => sum + i.quantity, 0)
  const totalPrice = items.reduce((sum, i) => sum + i.price * i.quantity, 0)

  const storeOpen = status?.open ?? false
  const stockAvailable = status?.stock_available ?? 0

  function getQty(id: number) {
    return items.find((i) => i.id === id)?.quantity ?? 0
  }

  function handleAdd(item: MenuItem) {
    addItem({ id: item.id, name: item.name, price: item.price })
  }

  function handleDecrement(item: MenuItem) {
    setQuantity(item.id, getQty(item.id) - 1)
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="w-7 h-7 rounded-full border-2 border-(--color-text-muted) border-t-(--color-primary) animate-spin" />
      </div>
    )
  }

  if (isError || !categories) {
    return (
      <div className="px-4 py-8 text-center">
        <p className="text-sm text-(--color-text-secondary)">No se pudo cargar el menú.</p>
      </div>
    )
  }

  return (
    <div className="pb-28 max-w-lg mx-auto">
      {/* Stock / schedule banner */}
      {storeOpen && stockAvailable > 0 ? (
        <div className="border-b border-(--color-primary)/20 px-4 py-2.5 flex items-center justify-between">
          <span className="text-sm text-(--color-primary) font-medium">
            {stockAvailable} pollos disponibles hoy
          </span>
          <span className="text-xs text-(--color-primary)/60">
            Abierto · hasta las {status!.closing_time}
          </span>
        </div>
      ) : (
        <div className="bg-[#3D2E10] border-b border-(--color-accent)/30 px-4 py-3">
          <p className="text-sm font-semibold text-(--color-accent)">Estamos cerrados</p>
          <p className="text-xs text-(--color-accent)/70 mt-0.5">
            {status
              ? nextOpeningLabel(status.open_days, status.opening_time)
              : 'Volvemos pronto'}
          </p>
        </div>
      )}

      {/* Category tabs */}
      <div className="sticky top-14 z-30 bg-(--color-background) border-b border-(--color-border)">
        <div className="flex overflow-x-auto gap-1.5 px-4 py-3 [scrollbar-width:none]">
          {categories.map((cat) => (
            <button
              key={cat.id}
              onClick={() => setActiveCategory(cat.id)}
              className={`shrink-0 px-4 py-1.5 rounded-(--radius-pill) text-sm font-medium transition-colors ${
                activeCategoryId === cat.id
                  ? 'bg-(--color-primary) text-(--color-background)'
                  : 'bg-(--color-surface) text-(--color-text-secondary)'
              }`}
            >
              {cat.name}
            </button>
          ))}
        </div>
      </div>

      {/* Items list */}
      <div className="px-4 py-4 flex flex-col gap-3">
        {activeItems.map((item) => {
          const qty = getQty(item.id)
          const canAdd = storeOpen && item.available
          return (
            <div
              key={item.id}
              className="bg-(--color-surface) rounded-(--radius-lg) p-4 flex items-center gap-4"
            >
              {item.image_url ? (
                <img
                  src={item.image_url}
                  alt={item.name}
                  className="w-16 h-16 rounded-(--radius-md) object-cover shrink-0"
                />
              ) : (
                <div className="w-16 h-16 rounded-(--radius-md) bg-(--color-surface-elevated) shrink-0 flex items-center justify-center text-2xl">
                  🍗
                </div>
              )}

              <div className="flex-1 min-w-0">
                <p className="text-sm font-semibold text-(--color-text-primary)">{item.name}</p>
                {item.description && (
                  <p className="text-xs text-(--color-text-secondary) mt-0.5 line-clamp-2">
                    {item.description}
                  </p>
                )}
                <p className="text-sm font-bold text-(--color-primary) mt-1.5">
                  {formatPrice(item.price)}
                </p>
              </div>

              <div className="flex items-center gap-2 shrink-0">
                {qty > 0 ? (
                  <>
                    <button
                      onClick={() => handleDecrement(item)}
                      className="w-7 h-7 rounded-full bg-(--color-surface-elevated) flex items-center justify-center text-(--color-text-primary)"
                    >
                      <Minus size={13} />
                    </button>
                    <span className="w-4 text-center text-sm font-bold text-(--color-text-primary)">
                      {qty}
                    </span>
                    <button
                      onClick={() => handleAdd(item)}
                      disabled={!canAdd}
                      className="w-7 h-7 rounded-full bg-(--color-primary) flex items-center justify-center text-(--color-background) disabled:opacity-40 disabled:cursor-not-allowed"
                    >
                      <Plus size={13} />
                    </button>
                  </>
                ) : (
                  <button
                    onClick={() => handleAdd(item)}
                    disabled={!canAdd}
                    className="w-7 h-7 rounded-full bg-(--color-primary) flex items-center justify-center text-(--color-background) disabled:opacity-40 disabled:cursor-not-allowed"
                  >
                    <Plus size={13} />
                  </button>
                )}
              </div>
            </div>
          )
        })}
      </div>

      {/* Floating cart CTA — encima del bottom nav (z-50 > z-40) */}
      {totalItems > 0 && storeOpen && (
        <div className="fixed bottom-20 left-0 right-0 z-50 px-4">
          <Link
            to="/carrito"
            className="flex items-center justify-between w-full bg-(--color-primary) text-(--color-background) font-semibold px-5 py-3.5 rounded-(--radius-pill) shadow-lg shadow-black/40"
          >
            <span className="bg-(--color-background)/20 text-xs font-bold px-2 py-0.5 rounded-full">
              {totalItems} {totalItems === 1 ? 'ítem' : 'ítems'}
            </span>
            <span className="flex items-center gap-2">
              <ShoppingCart size={15} />
              Continuar al carrito
            </span>
            <span className="text-sm font-bold">{formatPrice(totalPrice)}</span>
          </Link>
        </div>
      )}
    </div>
  )
}
