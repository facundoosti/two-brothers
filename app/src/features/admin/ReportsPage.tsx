import { TrendingUp, TrendingDown, Download } from 'lucide-react'
import AdminTopbar from './components/AdminTopbar'

// ── Mock data ──────────────────────────────────────────────────────────────────

const STATS = [
  { label: 'Ventas totales', value: '$192.400', trend: '+14%', up: true },
  { label: 'Órdenes completadas', value: '194', trend: '+6%', up: true },
  { label: 'Ítems vendidos', value: '389', trend: '+3%', up: true },
  { label: 'Ticket promedio', value: '$5.840', trend: '-2%', up: false },
]

const DAILY_SALES = [
  { day: 'Jue', value: 28400, orders: 22 },
  { day: 'Vie', value: 35200, orders: 31 },
  { day: 'Sáb', value: 54100, orders: 48 },
  { day: 'Dom', value: 44800, orders: 38 },
  { day: 'Jue', value: 30400, orders: 25 },
]

const TOP_ITEMS = [
  { name: 'Pollo entero al espiedo', sold: 203 },
  { name: 'Medio pollo al espiedo', sold: 134 },
  { name: 'Cuarto de pollo', sold: 52 },
]

const MAX_VALUE = Math.max(...DAILY_SALES.map(d => d.value))

// ── Page ───────────────────────────────────────────────────────────────────────

export default function ReportsPage() {
  return (
    <>
      <AdminTopbar
        title="Reportes"
        subtitle="Análisis de ventas y performance"
        actions={
          <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-(--color-border) text-sm text-(--color-text-secondary) hover:text-(--color-text-primary) transition-colors">
            <Download size={14} /> Exportar CSV
          </button>
        }
      />

      <div className="flex-1 p-8 flex flex-col gap-6 overflow-y-auto">
        {/* Stat cards */}
        <div className="grid grid-cols-4 gap-4">
          {STATS.map((s) => (
            <div key={s.label} className="bg-(--color-surface) rounded-xl p-5 border border-(--color-border) flex flex-col gap-2">
              <div className="flex items-center justify-between">
                <p className="text-xs text-(--color-text-secondary)">{s.label}</p>
                <span className={`flex items-center gap-0.5 text-xs font-medium ${s.up ? 'text-[#40C97F]' : 'text-[#E05252]'}`}>
                  {s.up ? <TrendingUp size={12} /> : <TrendingDown size={12} />}
                  {s.trend}
                </span>
              </div>
              <p className="text-3xl font-bold text-(--color-text-primary)">{s.value}</p>
              <p className="text-xs text-(--color-text-muted)">vs semana anterior</p>
            </div>
          ))}
        </div>

        {/* Charts row */}
        <div className="grid grid-cols-[1fr_320px] gap-5">
          {/* Bar chart */}
          <div className="bg-(--color-surface) rounded-xl border border-(--color-border) p-6 flex flex-col gap-5">
            <div className="flex items-center justify-between">
              <h2 className="font-semibold text-(--color-text-primary)">Ventas diarias</h2>
              <div className="flex items-center gap-3 text-xs">
                <span className="flex items-center gap-1.5 text-(--color-text-secondary)">
                  <span className="w-2.5 h-2.5 rounded-sm bg-(--color-primary)" /> Ingresos
                </span>
                <span className="flex items-center gap-1.5 text-(--color-text-secondary)">
                  <span className="w-2.5 h-2.5 rounded-sm bg-(--color-surface-elevated) border border-(--color-border)" /> Semana anterior
                </span>
              </div>
            </div>

            {/* Bars */}
            <div className="flex items-end gap-4 h-44 px-2">
              {DAILY_SALES.map((d, idx) => {
                const heightPct = (d.value / MAX_VALUE) * 100
                return (
                  <div key={idx} className="flex-1 flex flex-col items-center gap-2">
                    <p className="text-xs text-(--color-text-muted)">${(d.value / 1000).toFixed(0)}k</p>
                    <div className="w-full flex flex-col justify-end" style={{ height: '120px' }}>
                      <div
                        className="w-full rounded-t-md bg-(--color-primary) transition-all"
                        style={{ height: `${heightPct}%` }}
                      />
                    </div>
                    <p className="text-xs text-(--color-text-secondary)">{d.day}</p>
                  </div>
                )
              })}
            </div>
          </div>

          {/* Top items */}
          <div className="bg-(--color-surface) rounded-xl border border-(--color-border) p-5 flex flex-col gap-4">
            <h2 className="font-semibold text-(--color-text-primary)">Ítems más vendidos</h2>
            <div className="flex flex-col gap-3">
              {TOP_ITEMS.map((item, idx) => {
                const pct = (item.sold / TOP_ITEMS[0].sold) * 100
                return (
                  <div key={idx} className="flex flex-col gap-1.5">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-(--color-text-primary) truncate pr-2">{item.name}</span>
                      <span className="font-semibold text-(--color-text-primary) shrink-0">{item.sold}</span>
                    </div>
                    <div className="h-1.5 rounded-full bg-(--color-surface-elevated) overflow-hidden">
                      <div
                        className="h-full rounded-full bg-(--color-primary)"
                        style={{ width: `${pct}%` }}
                      />
                    </div>
                  </div>
                )
              })}
            </div>

            {/* Period selector */}
            <div className="mt-auto pt-4 border-t border-(--color-border) flex gap-1.5">
              {['Esta semana', 'Este mes', 'Este año'].map((p, idx) => (
                <button
                  key={p}
                  className={`flex-1 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                    idx === 0
                      ? 'bg-(--color-primary) text-black'
                      : 'text-(--color-text-secondary) hover:text-(--color-text-primary) hover:bg-(--color-surface-elevated)'
                  }`}
                >
                  {p}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </>
  )
}
