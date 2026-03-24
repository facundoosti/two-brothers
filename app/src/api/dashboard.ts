import { useQuery } from '@tanstack/react-query'
import { api } from '@/lib/api'
import type { DailyStock } from '@/types/orders'

interface DashboardStats {
  orders_today: number
  orders_by_status: Record<string, number>
  revenue_today: number
  pending_payment_count: number
}

export function useDashboard() {
  return useQuery({
    queryKey: ['dashboard'],
    queryFn: () => api.get<DashboardStats>('/api/v1/dashboard'),
    refetchInterval: 30_000,
  })
}

export function useDailyStock() {
  return useQuery({
    queryKey: ['daily_stocks'],
    queryFn: () => api.get<DailyStock[]>('/api/v1/daily_stocks'),
  })
}
