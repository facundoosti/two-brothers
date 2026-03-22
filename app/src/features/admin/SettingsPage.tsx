import { useState, useEffect } from 'react'
import { Save } from 'lucide-react'
import AdminTopbar from './components/AdminTopbar'
import { useSettings, useUpdateSettings } from '@/api/settings'
import { cn } from '@/lib/utils'

const DAYS = [
  { value: '0', label: 'Dom' },
  { value: '1', label: 'Lun' },
  { value: '2', label: 'Mar' },
  { value: '3', label: 'Mié' },
  { value: '4', label: 'Jue' },
  { value: '5', label: 'Vie' },
  { value: '6', label: 'Sáb' },
]

export default function SettingsPage() {
  const { data: settings, isLoading } = useSettings()
  const update = useUpdateSettings()

  const [form, setForm] = useState({
    store_name:           '',
    store_address:        '',
    daily_chicken_stock:  '',
    mp_alias:             '',
    open_days:            '4,5,6,0',
    opening_time:         '20:00',
    closing_time:         '00:00',
    delivery_fee:         '0',
    delivery_fee_enabled: 'false',
  })

  // Populate form once settings load
  useEffect(() => {
    if (!settings) return
    setForm({
      store_name:           settings.store_name           ?? '',
      store_address:        settings.store_address        ?? '',
      daily_chicken_stock:  settings.daily_chicken_stock  ?? '100',
      mp_alias:             settings.mp_alias             ?? '',
      open_days:            settings.open_days            ?? '4,5,6,0',
      opening_time:         settings.opening_time         ?? '20:00',
      closing_time:         settings.closing_time         ?? '00:00',
      delivery_fee:         settings.delivery_fee         || '0',
      delivery_fee_enabled: settings.delivery_fee_enabled || 'false',
    })
  }, [settings])

  function field(key: keyof typeof form) {
    return {
      value: form[key],
      onChange: (e: React.ChangeEvent<HTMLInputElement>) =>
        setForm((f) => ({ ...f, [key]: e.target.value })),
    }
  }

  const selectedDays = form.open_days.split(',').filter(Boolean)

  function toggleDay(day: string) {
    const days = selectedDays.includes(day)
      ? selectedDays.filter((d) => d !== day)
      : [...selectedDays, day]
    setForm((f) => ({ ...f, open_days: days.join(',') }))
  }

  function handleSave() {
    update.mutate(form)
  }

  if (isLoading) {
    return (
      <>
        <AdminTopbar title="Configuración" />
        <div className="flex-1 flex items-center justify-center">
          <div className="spinner" />
        </div>
      </>
    )
  }

  return (
    <>
      <AdminTopbar
        title="Configuración"
        subtitle="Horario, stock y datos del local"
        actions={
          <button
            onClick={handleSave}
            disabled={update.isPending}
            className="flex items-center gap-2 px-4 py-2 bg-(--color-primary) text-black text-sm font-semibold rounded-(--radius-pill) disabled:opacity-50 transition-opacity"
          >
            <Save size={14} />
            {update.isPending ? 'Guardando...' : 'Guardar cambios'}
          </button>
        }
      />

      <div className="flex-1 p-8 overflow-y-auto">
        <div className="max-w-2xl flex flex-col gap-6">

          {update.isSuccess && (
            <div className="px-4 py-3 rounded-(--radius-lg) bg-(--color-primary)/10 border border-(--color-primary)/30 text-sm text-(--color-primary)">
              Configuración guardada correctamente.
            </div>
          )}

          {/* Local */}
          <section className="card p-6 flex flex-col gap-4">
            <h2 className="text-sm font-semibold text-(--color-text-primary)">Datos del local</h2>
            <div className="flex flex-col gap-3">
              <label className="flex flex-col gap-1.5">
                <span className="text-xs text-(--color-text-secondary)">Nombre del local</span>
                <input className="form-input" placeholder="Two Brothers" {...field('store_name')} />
              </label>
              <label className="flex flex-col gap-1.5">
                <span className="text-xs text-(--color-text-secondary)">Dirección</span>
                <input className="form-input" placeholder="Washington 133, Dolores" {...field('store_address')} />
              </label>
            </div>
          </section>

          {/* Horario */}
          <section className="card p-6 flex flex-col gap-4">
            <h2 className="text-sm font-semibold text-(--color-text-primary)">Horario de atención</h2>

            <div className="flex flex-col gap-1.5">
              <span className="text-xs text-(--color-text-secondary)">Días abiertos</span>
              <div className="flex gap-2">
                {DAYS.map(({ value, label }) => (
                  <button
                    key={value}
                    type="button"
                    onClick={() => toggleDay(value)}
                    className={cn(
                      'w-10 h-10 rounded-lg text-xs font-medium border transition-colors',
                      selectedDays.includes(value)
                        ? 'bg-(--color-primary)/15 border-(--color-primary)/50 text-(--color-primary)'
                        : 'bg-(--color-surface-elevated) border-(--color-border) text-(--color-text-muted)',
                    )}
                  >
                    {label}
                  </button>
                ))}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <label className="flex flex-col gap-1.5">
                <span className="text-xs text-(--color-text-secondary)">Apertura</span>
                <input type="time" className="form-input" {...field('opening_time')} />
              </label>
              <label className="flex flex-col gap-1.5">
                <span className="text-xs text-(--color-text-secondary)">Cierre</span>
                <input type="time" className="form-input" {...field('closing_time')} />
              </label>
            </div>
          </section>

          {/* Stock */}
          <section className="card p-6 flex flex-col gap-4">
            <h2 className="text-sm font-semibold text-(--color-text-primary)">Stock</h2>
            <label className="flex flex-col gap-1.5">
              <span className="text-xs text-(--color-text-secondary)">Pollos disponibles por día</span>
              <input
                type="number"
                min="0"
                className="form-input max-w-xs"
                {...field('daily_chicken_stock')}
              />
              <span className="text-xs text-(--color-text-muted)">
                El stock del día de hoy no cambia — aplica desde mañana.
              </span>
            </label>
          </section>

          {/* Pagos */}
          <section className="card p-6 flex flex-col gap-4">
            <h2 className="text-sm font-semibold text-(--color-text-primary)">Pagos</h2>
            <label className="flex flex-col gap-1.5">
              <span className="text-xs text-(--color-text-secondary)">Alias Mercado Pago</span>
              <input
                className="form-input max-w-xs font-mono"
                placeholder="twobrothers.mp"
                {...field('mp_alias')}
              />
              <span className="text-xs text-(--color-text-muted)">
                Se muestra al cliente cuando elige pago por transferencia.
              </span>
            </label>
          </section>

          {/* Delivery */}
          <section className="card p-6 flex flex-col gap-4">
            <h2 className="text-sm font-semibold text-(--color-text-primary)">Costo de envío</h2>

            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-(--color-text-primary)">Cobrar costo de envío</p>
                <p className="text-xs text-(--color-text-muted) mt-0.5">
                  Se suma al total en el checkout cuando el cliente elige delivery.
                </p>
              </div>
              <button
                type="button"
                onClick={() =>
                  setForm((f) => ({
                    ...f,
                    delivery_fee_enabled: f.delivery_fee_enabled === 'true' ? 'false' : 'true',
                  }))
                }
                className={cn(
                  'relative inline-flex h-6 w-11 shrink-0 rounded-full border-2 border-transparent transition-colors',
                  form.delivery_fee_enabled === 'true'
                    ? 'bg-(--color-primary)'
                    : 'bg-(--color-surface-elevated)',
                )}
              >
                <span
                  className={cn(
                    'inline-block h-5 w-5 rounded-full bg-white shadow transition-transform',
                    form.delivery_fee_enabled === 'true' ? 'translate-x-5' : 'translate-x-0',
                  )}
                />
              </button>
            </div>

            {form.delivery_fee_enabled === 'true' && (
              <label className="flex flex-col gap-1.5">
                <span className="text-xs text-(--color-text-secondary)">Precio del envío (ARS)</span>
                <input
                  type="number"
                  min="0"
                  className="form-input max-w-xs"
                  placeholder="500"
                  {...field('delivery_fee')}
                />
              </label>
            )}
          </section>

        </div>
      </div>
    </>
  )
}
