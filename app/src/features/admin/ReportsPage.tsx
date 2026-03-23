import { useState } from 'react'
import { TrendingUp, TrendingDown, Download, ArrowRight } from 'lucide-react'
import AdminTopbar from './components/AdminTopbar'
import { useReports, type ReportPeriod, type TransitionMetrics } from '@/api/reports'

// ── Helpers ────────────────────────────────────────────────────────────────────

function formatDayLabel(iso: string, period: ReportPeriod): string {
  const d = new Date(iso + 'T12:00:00') // avoid UTC offset issues
  if (period === 'year') {
    return d.toLocaleDateString('es-AR', { month: 'short' })
  }
  if (period === 'month') {
    return d.getDate().toString()
  }
  return d.toLocaleDateString('es-AR', { weekday: 'short' }).replace('.', '')
}

function fmtMoney(n: number): string {
  if (n >= 1_000_000) return `$${(n / 1_000_000).toFixed(1)}M`
  if (n >= 1_000) return `$${(n / 1_000).toFixed(0)}k`
  return `$${n.toFixed(0)}`
}

function TrendBadge({ value }: { value: number }) {
  const up = value >= 0
  return (
    <span className={`flex items-center gap-0.5 text-xs font-medium ${up ? 'text-[#40C97F]' : 'text-[#E05252]'}`}>
      {up ? <TrendingUp size={12} /> : <TrendingDown size={12} />}
      {value > 0 ? '+' : ''}{value}%
    </span>
  )
}

// ── Transition metrics ─────────────────────────────────────────────────────────

function fmtMinutes(mins: number | null): string {
  if (mins == null) return '—'
  if (mins < 1) return '<1 min'
  return `${Math.round(mins)} min`
}

const TRANSITIONS: { key: keyof TransitionMetrics; label: string; from: string; to: string }[] = [
  { key: 'created_to_confirmed',    label: 'Confirmación de pago',  from: 'Creada',        to: 'Confirmada'    },
  { key: 'confirmed_to_preparing',  label: 'Inicio preparación',    from: 'Confirmada',    to: 'Preparando'    },
  { key: 'preparing_to_ready',      label: 'Tiempo de preparación', from: 'Preparando',    to: 'Lista'         },
  { key: 'ready_to_delivering',     label: 'Espera despacho',       from: 'Lista',         to: 'En camino'     },
  { key: 'delivering_to_delivered', label: 'Tiempo de entrega',     from: 'En camino',     to: 'Entregada'     },
  { key: 'total',                   label: 'Tiempo total',          from: 'Creada',        to: 'Entregada'     },
]

// ── Page ───────────────────────────────────────────────────────────────────────

const PERIODS: { key: ReportPeriod; label: string }[] = [
  { key: 'week',  label: 'Esta semana' },
  { key: 'month', label: 'Este mes' },
  { key: 'year',  label: 'Este año' },
]

export default function ReportsPage() {
  const [period, setPeriod] = useState<ReportPeriod>('week')
  const { data, isLoading } = useReports(period)

  const stats = data?.stats
  const dailySales = data?.daily_sales ?? []
  const topItems = data?.top_items ?? []
  const metrics = data?.transition_metrics ?? null
  const maxValue = dailySales.length > 0 ? Math.max(...dailySales.map(d => d.value)) : 1

  const STAT_CARDS = stats
    ? [
        { label: 'Ventas totales',      value: fmtMoney(stats.total_sales),   trend: stats.trends.sales      },
        { label: 'Órdenes completadas', value: String(stats.total_orders),     trend: stats.trends.orders     },
        { label: 'Ítems vendidos',      value: String(stats.total_items),      trend: null                    },
        { label: 'Ticket promedio',     value: fmtMoney(stats.avg_ticket),     trend: stats.trends.avg_ticket },
      ]
    : null

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
          {isLoading || !STAT_CARDS
            ? Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className="bg-(--color-surface) rounded-xl p-5 border border-(--color-border) h-24 animate-pulse" />
              ))
            : STAT_CARDS.map((s) => (
                <div key={s.label} className="bg-(--color-surface) rounded-xl p-5 border border-(--color-border) flex flex-col gap-2">
                  <div className="flex items-center justify-between">
                    <p className="text-xs text-(--color-text-secondary)">{s.label}</p>
                    {s.trend !== null ? <TrendBadge value={s.trend} /> : null}
                  </div>
                  <p className="text-3xl font-bold text-(--color-text-primary)">{s.value}</p>
                  <p className="text-xs text-(--color-text-muted)">vs período anterior</p>
                </div>
              ))}
        </div>

        {/* Charts row */}
        <div className="grid grid-cols-[1fr_320px] gap-5">
          {/* Bar chart */}
          <div className="bg-(--color-surface) rounded-xl border border-(--color-border) p-6 flex flex-col gap-5">
            <div className="flex items-center justify-between">
              <h2 className="font-semibold text-(--color-text-primary)">Ventas por día</h2>
              <div className="flex items-center gap-1">
                {PERIODS.map(p => (
                  <button
                    key={p.key}
                    onClick={() => setPeriod(p.key)}
                    className={`px-3 py-1 rounded-lg text-xs font-medium transition-colors ${
                      period === p.key
                        ? 'bg-(--color-primary) text-black'
                        : 'text-(--color-text-secondary) hover:text-(--color-text-primary) hover:bg-(--color-surface-elevated)'
                    }`}
                  >
                    {p.label}
                  </button>
                ))}
              </div>
            </div>

            {isLoading ? (
              <div className="h-44 flex items-center justify-center">
                <div className="w-6 h-6 rounded-full border-2 border-(--color-border) border-t-(--color-primary) animate-spin" />
              </div>
            ) : dailySales.length === 0 ? (
              <div className="h-44 flex items-center justify-center">
                <p className="text-sm text-(--color-text-muted)">Sin ventas en este período</p>
              </div>
            ) : (
              <div className="flex items-end gap-3 h-44 px-2">
                {dailySales.map((d, idx) => {
                  const heightPct = (d.value / maxValue) * 100
                  return (
                    <div key={idx} className="flex-1 flex flex-col items-center gap-2 group relative">
                      {/* Tooltip */}
                      <div className="absolute bottom-full mb-1 hidden group-hover:flex flex-col items-center pointer-events-none">
                        <div className="bg-(--color-surface-elevated) border border-(--color-border) rounded-lg px-2.5 py-1.5 text-xs whitespace-nowrap">
                          <p className="text-(--color-text-primary) font-semibold">{fmtMoney(d.value)}</p>
                          <p className="text-(--color-text-muted)">{d.orders} órdenes</p>
                        </div>
                      </div>
                      <p className="text-xs text-(--color-text-muted)">{fmtMoney(d.value)}</p>
                      <div className="w-full flex flex-col justify-end" style={{ height: '120px' }}>
                        <div
                          className="w-full rounded-t-md bg-(--color-primary) transition-all"
                          style={{ height: `${heightPct}%` }}
                        />
                      </div>
                      <p className="text-xs text-(--color-text-secondary)">{formatDayLabel(d.day, period)}</p>
                    </div>
                  )
                })}
              </div>
            )}
          </div>

          {/* Top items */}
          <div className="bg-(--color-surface) rounded-xl border border-(--color-border) p-5 flex flex-col gap-4">
            <h2 className="font-semibold text-(--color-text-primary)">Ítems más vendidos</h2>
            {isLoading ? (
              <div className="flex flex-col gap-3">
                {Array.from({ length: 3 }).map((_, i) => (
                  <div key={i} className="h-8 rounded bg-(--color-surface-elevated) animate-pulse" />
                ))}
              </div>
            ) : topItems.length === 0 ? (
              <p className="text-sm text-(--color-text-muted) text-center py-4">Sin datos</p>
            ) : (
              <div className="flex flex-col gap-3">
                {topItems.map((item, idx) => {
                  const pct = (item.sold / topItems[0].sold) * 100
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
            )}
          </div>
        </div>

        {/* Transition metrics */}
        <div className="bg-(--color-surface) rounded-xl border border-(--color-border) p-6">
          <h2 className="font-semibold text-(--color-text-primary) mb-5">Tiempos por etapa</h2>
          {isLoading ? (
            <div className="grid grid-cols-6 gap-3">
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="h-20 rounded-lg bg-(--color-surface-elevated) animate-pulse" />
              ))}
            </div>
          ) : (
            <div className="flex items-stretch gap-0">
              {TRANSITIONS.map((t, idx) => {
                const minutes = metrics?.[t.key] ?? null
                const isTotal = t.key === 'total'
                return (
                  <div key={t.key} className="flex items-center flex-1 gap-0">
                    <div className={`flex-1 flex flex-col gap-2 px-4 py-3 rounded-xl ${isTotal ? 'bg-(--color-primary)/10 border border-(--color-primary)/20' : 'bg-(--color-surface-elevated)'}`}>
                      <p className="text-[10px] uppercase tracking-wide text-(--color-text-muted)">{t.label}</p>
                      <p className={`text-2xl font-bold ${isTotal ? 'text-(--color-primary)' : 'text-(--color-text-primary)'}`}>
                        {fmtMinutes(minutes)}
                      </p>
                      <div className="flex items-center gap-1 text-[10px] text-(--color-text-muted)">
                        <span>{t.from}</span>
                        <ArrowRight size={9} />
                        <span>{t.to}</span>
                      </div>
                    </div>
                    {idx < TRANSITIONS.length - 1 && (
                      <ArrowRight size={14} className="text-(--color-border) shrink-0 mx-1" />
                    )}
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </div>
    </>
  )
}
