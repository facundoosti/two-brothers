import { useQuery } from '@tanstack/react-query'
import { api } from '@/lib/api'

export interface StoreStatus {
  open: boolean
  stock_available: boolean
  opening_time: string
  closing_time: string
  open_days: number[]   // 0 = domingo … 6 = sábado
  delivery_fee: number
  delivery_fee_enabled: boolean
}

export function useStoreStatus() {
  return useQuery({
    queryKey: ['store_status'],
    queryFn: () => api.get<StoreStatus>('/api/v1/store_status'),
    refetchInterval: 60_000,  // cada minuto
    staleTime: 30_000,
  })
}
