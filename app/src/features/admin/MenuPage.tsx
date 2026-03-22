import { useState } from 'react'
import { Plus, Pencil, Trash2, X, Check } from 'lucide-react'
import AdminTopbar from './components/AdminTopbar'
import { useCategories, useCreateCategory, useUpdateCategory, useDeleteCategory } from '@/api/categories'
import { useCreateMenuItem, useUpdateMenuItem, useDeleteMenuItem } from '@/api/menuItems'
import type { CategoryWithItems, MenuItem } from '@/types/orders'

interface ItemForm {
  id?: number
  categoryId: number
  name: string
  description: string
  price: string
  available: boolean
}

interface CatForm {
  id?: number
  name: string
}

const EMPTY_ITEM_FORM = (categoryId: number): ItemForm => ({
  categoryId,
  name: '',
  description: '',
  price: '',
  available: true,
})

export default function MenuPage() {
  const { data: categories = [], isLoading } = useCategories()
  const createItem = useCreateMenuItem()
  const updateItem = useUpdateMenuItem()
  const deleteItem = useDeleteMenuItem()
  const createCat = useCreateCategory()
  const updateCat = useUpdateCategory()
  const deleteCat = useDeleteCategory()

  const [selectedCategoryId, setSelectedCategoryId] = useState<number | null>(null)
  const [itemForm, setItemForm] = useState<ItemForm | null>(null)
  const [catForm, setCatForm] = useState<CatForm | null>(null)

  const activeCategoryId = selectedCategoryId ?? categories[0]?.id
  const selectedCategory: CategoryWithItems | undefined = categories.find(c => c.id === activeCategoryId)
  const visibleItems = selectedCategory?.menu_items ?? []
  const activeCount = visibleItems.filter(i => i.available).length

  function startEditItem(item: MenuItem) {
    setCatForm(null)
    setItemForm({
      id: item.id,
      categoryId: item.category_id,
      name: item.name,
      description: item.description ?? '',
      price: String(item.price),
      available: item.available,
    })
  }

  function startCreateItem() {
    setCatForm(null)
    setItemForm(EMPTY_ITEM_FORM(activeCategoryId))
  }

  function handleSaveItem() {
    if (!itemForm) return
    const payload = {
      name: itemForm.name,
      description: itemForm.description,
      price: Number(itemForm.price),
      category_id: itemForm.categoryId,
      available: itemForm.available,
    }
    if (itemForm.id) {
      updateItem.mutate({ id: itemForm.id, ...payload }, { onSuccess: () => setItemForm(null) })
    } else {
      createItem.mutate(payload, { onSuccess: () => setItemForm(null) })
    }
  }

  function handleDeleteItem(id: number) {
    if (!confirm('¿Eliminás este ítem?')) return
    deleteItem.mutate(id)
  }

  function startEditCat(cat: CategoryWithItems) {
    setItemForm(null)
    setCatForm({ id: cat.id, name: cat.name })
  }

  function startCreateCat() {
    setItemForm(null)
    setCatForm({ name: '' })
  }

  function handleSaveCat() {
    if (!catForm) return
    if (catForm.id) {
      updateCat.mutate({ id: catForm.id, name: catForm.name }, { onSuccess: () => setCatForm(null) })
    } else {
      createCat.mutate(catForm.name, {
        onSuccess: (cat) => {
          setCatForm(null)
          setSelectedCategoryId(cat.id)
        },
      })
    }
  }

  function handleDeleteCat(cat: CategoryWithItems) {
    if (!confirm(`¿Eliminás la categoría "${cat.name}" y todos sus ítems?`)) return
    deleteCat.mutate(cat.id, {
      onSuccess: () => {
        if (selectedCategoryId === cat.id) setSelectedCategoryId(null)
      },
    })
  }

  const isSavingItem = createItem.isPending || updateItem.isPending
  const isSavingCat = createCat.isPending || updateCat.isPending
  const itemError = (createItem.error ?? updateItem.error)?.message
  const catError = (createCat.error ?? updateCat.error)?.message

  return (
    <>
      <AdminTopbar
        title="Menú"
        subtitle="Categorías e ítems de tu local"
        actions={
          <button onClick={startCreateItem} className="btn-primary px-3 py-1.5">
            <Plus size={14} /> Nuevo ítem
          </button>
        }
      />

      <div className="flex-1 flex overflow-hidden">
        {/* Category sidebar */}
        <aside className="w-52 shrink-0 border-r border-(--color-border) flex flex-col bg-(--color-sidebar)">
          <div className="px-4 py-3 border-b border-(--color-border) flex items-center justify-between">
            <p className="section-label">Categorías</p>
            <button
              onClick={startCreateCat}
              className="w-6 h-6 flex items-center justify-center rounded hover:bg-(--color-surface) text-(--color-text-muted) hover:text-(--color-primary) transition-colors"
            >
              <Plus size={13} />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto py-2 px-2 flex flex-col gap-0.5">
            {isLoading ? (
              <p className="px-3 py-4 text-xs text-(--color-text-muted)">Cargando...</p>
            ) : (
              categories.map((cat) => (
                <div
                  key={cat.id}
                  className={`group flex items-center justify-between px-3 py-2.5 rounded-lg transition-colors cursor-pointer ${
                    cat.id === activeCategoryId
                      ? 'bg-(--color-primary)/10 text-(--color-primary)'
                      : 'text-(--color-text-secondary) hover:text-(--color-text-primary) hover:bg-(--color-surface)'
                  }`}
                  onClick={() => setSelectedCategoryId(cat.id)}
                >
                  <span className="text-sm truncate flex-1">{cat.id === activeCategoryId ? <strong>{cat.name}</strong> : cat.name}</span>
                  <div className="flex items-center gap-1 shrink-0">
                    <span className="text-xs text-(--color-text-muted) group-hover:hidden">{cat.menu_items.length}</span>
                    <button
                      onClick={e => { e.stopPropagation(); startEditCat(cat) }}
                      className="hidden group-hover:flex w-5 h-5 items-center justify-center rounded hover:text-(--color-primary)"
                    >
                      <Pencil size={11} />
                    </button>
                    <button
                      onClick={e => { e.stopPropagation(); handleDeleteCat(cat) }}
                      disabled={deleteCat.isPending}
                      className="hidden group-hover:flex w-5 h-5 items-center justify-center rounded hover:text-(--color-destructive)"
                    >
                      <Trash2 size={11} />
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>

          {/* Category form */}
          {catForm !== null && (
            <div className="border-t border-(--color-border) p-3 flex flex-col gap-2">
              <p className="text-xs font-medium text-(--color-text-secondary)">
                {catForm.id ? 'Renombrar' : 'Nueva categoría'}
              </p>
              <input
                value={catForm.name}
                onChange={e => setCatForm(f => f && ({ ...f, name: e.target.value }))}
                onKeyDown={e => e.key === 'Enter' && handleSaveCat()}
                placeholder="Nombre"
                autoFocus
                className="form-input text-sm py-1.5"
              />
              {catError && <p className="text-xs text-(--color-destructive)">{catError}</p>}
              <div className="flex gap-1.5">
                <button onClick={() => setCatForm(null)} className="btn-ghost flex-1 py-1.5 text-xs">Cancelar</button>
                <button onClick={handleSaveCat} disabled={isSavingCat || !catForm.name.trim()} className="btn-primary flex-1 py-1.5 text-xs">
                  {isSavingCat ? '...' : <Check size={13} />}
                </button>
              </div>
            </div>
          )}
        </aside>

        {/* Items panel */}
        <div className="flex-1 flex flex-col overflow-hidden">
          <div className="flex items-center justify-between px-6 py-3 border-b border-(--color-border) bg-(--color-sidebar)">
            <p className="text-sm font-medium text-(--color-text-primary)">{selectedCategory?.name ?? '—'}</p>
            <p className="text-xs text-(--color-text-muted)">{activeCount} ítems activos</p>
          </div>

          <div className="flex-1 overflow-y-auto">
            <table className="w-full text-sm">
              <thead className="sticky top-0 bg-(--color-sidebar) z-10">
                <tr className="border-b border-(--color-border)">
                  {['Nombre', 'Descripción', 'Precio', 'Estado', 'Acciones'].map(h => (
                    <th key={h} className="table-th">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {visibleItems.map((item) => (
                  <tr key={item.id} className="table-row">
                    <td className="table-td font-medium text-(--color-text-primary)">{item.name}</td>
                    <td className="table-td text-(--color-text-secondary) max-w-[280px] truncate">{item.description}</td>
                    <td className="table-td font-medium text-(--color-text-primary)">${Number(item.price).toLocaleString('es-AR')}</td>
                    <td className="table-td">
                      <span className={`badge ${item.available ? 'bg-(--color-primary)/15 text-(--color-primary)' : 'bg-(--color-text-secondary)/15 text-(--color-text-secondary)'}`}>
                        {item.available ? 'Activo' : 'Inactivo'}
                      </span>
                    </td>
                    <td className="table-td">
                      <div className="flex items-center gap-1">
                        <button onClick={() => startEditItem(item)} className="btn-icon hover:text-(--color-primary) hover:bg-(--color-primary)/10">
                          <Pencil size={13} />
                        </button>
                        <button
                          onClick={() => handleDeleteItem(item.id)}
                          disabled={deleteItem.isPending}
                          className="btn-icon hover:text-(--color-destructive) hover:bg-(--color-destructive)/10"
                        >
                          <Trash2 size={13} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Item form */}
          {itemForm !== null && (
            <div className="border-t border-(--color-border) bg-(--color-surface) p-5">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-sm font-semibold text-(--color-text-primary)">
                  {itemForm.id ? 'Editar ítem' : 'Nuevo ítem'}
                </h3>
                <button onClick={() => setItemForm(null)} className="btn-icon"><X size={16} /></button>
              </div>

              <div className="grid grid-cols-[1fr_200px] gap-4">
                <div className="flex flex-col gap-3">
                  <div className="flex flex-col gap-1.5">
                    <label className="text-xs text-(--color-text-secondary)">Nombre</label>
                    <input
                      value={itemForm.name}
                      onChange={e => setItemForm(f => f && ({ ...f, name: e.target.value }))}
                      placeholder="Ej: Pollo entero al espiedo"
                      className="form-input"
                    />
                  </div>
                  <div className="flex flex-col gap-1.5">
                    <label className="text-xs text-(--color-text-secondary)">Descripción</label>
                    <input
                      value={itemForm.description}
                      onChange={e => setItemForm(f => f && ({ ...f, description: e.target.value }))}
                      placeholder="Pollo completo criado de chacra"
                      className="form-input"
                    />
                  </div>
                </div>

                <div className="flex flex-col gap-3">
                  <div className="flex flex-col gap-1.5">
                    <label className="text-xs text-(--color-text-secondary)">Precio</label>
                    <input
                      value={itemForm.price}
                      onChange={e => setItemForm(f => f && ({ ...f, price: e.target.value }))}
                      placeholder="8500"
                      type="number"
                      className="form-input"
                    />
                  </div>
                  <div className="flex flex-col gap-1.5">
                    <label className="text-xs text-(--color-text-secondary)">Disponibilidad</label>
                    <button
                      onClick={() => setItemForm(f => f && ({ ...f, available: !f.available }))}
                      className={`flex items-center gap-2 px-3 py-2 rounded-lg border text-sm font-medium transition-colors ${
                        itemForm.available
                          ? 'bg-(--color-primary)/10 border-(--color-primary)/40 text-(--color-primary)'
                          : 'bg-(--color-surface-elevated) border-(--color-border) text-(--color-text-secondary)'
                      }`}
                    >
                      <span className={`w-2 h-2 rounded-full ${itemForm.available ? 'bg-(--color-primary)' : 'bg-(--color-text-muted)'}`} />
                      {itemForm.available ? 'Activo' : 'Inactivo'}
                    </button>
                  </div>

                  {itemError && (
                    <p className="text-xs text-(--color-destructive)">{itemError}</p>
                  )}

                  <div className="flex gap-2 mt-auto">
                    <button onClick={() => setItemForm(null)} className="btn-ghost flex-1 py-2">Cancelar</button>
                    <button onClick={handleSaveItem} disabled={isSavingItem} className="btn-primary flex-1 py-2">
                      {isSavingItem ? 'Guardando...' : 'Guardar'}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </>
  )
}
