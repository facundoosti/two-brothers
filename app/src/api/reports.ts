import { useQuery } from '@tanstack/react-query'
import { api } from '@/lib/api'

export type ReportPeriod = 'week' | 'month' | 'year'

export interface ReportStats {
  total_sales: number
  total_orders: number
  total_items: number
  avg_ticket: number
  trends: {
    sales: number
    orders: number
    avg_ticket: number
  }
}

export interface DailySale {
  day: string   // ISO date string "2026-03-22"
  value: number
  orders: number
}

export interface TopItem {
  name: string
  sold: number
}

export interface TransitionMetrics {
  created_to_confirmed: number | null
  confirmed_to_preparing: number | null
  preparing_to_ready: number | null
  ready_to_delivering: number | null
  delivering_to_delivered: number | null
  total: number | null
}

export interface ReportsData {
  stats: ReportStats
  daily_sales: DailySale[]
  top_items: TopItem[]
  transition_metrics: TransitionMetrics
}

export function useReports(period: ReportPeriod = 'week') {
  return useQuery({
    queryKey: ['reports', period],
    queryFn: () => api.get<ReportsData>(`/api/v1/reports?period=${period}`),
    staleTime: 60_000,
  })
}
