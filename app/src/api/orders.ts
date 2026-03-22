import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'
import type { Order, OrderModality, PaymentMethod, OrderStatus } from '@/types/orders'

interface PagyMeta {
  page: number
  pages: number
  count: number
  limit: number
  from: number
  to: number
  prev: number | null
  next: number | null
}

interface OrdersResponse {
  data: Order[]
  pagy: PagyMeta
}

interface OrderFilters {
  status?: OrderStatus
  modality?: OrderModality
  date?: string
  page?: number
}

export function useOrders(filters: OrderFilters = {}) {
  const params = new URLSearchParams()
  if (filters.status) params.set('status', filters.status)
  if (filters.modality) params.set('modality', filters.modality)
  if (filters.date) params.set('date', filters.date)
  if (filters.page) params.set('page', String(filters.page))

  const query = params.toString()
  return useQuery({
    queryKey: ['orders', filters],
    queryFn: () => api.get<OrdersResponse>(`/api/v1/orders${query ? `?${query}` : ''}`),
  })
}

export function useOrder(id: number | string) {
  return useQuery({
    queryKey: ['orders', id],
    queryFn: () => api.get<Order>(`/api/v1/orders/${id}`),
    enabled: !!id,
  })
}

interface CreateOrderPayload {
  modality: OrderModality
  payment_method: PaymentMethod
  delivery_address?: string
  order_items_attributes: Array<{
    menu_item_id: number
    quantity: number
    unit_price: number
    notes?: string
  }>
}

export function useCreateOrder() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (payload: CreateOrderPayload) =>
      api.post<Order>('/api/v1/orders', { order: payload }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] })
    },
  })
}

export function useConfirmPayment() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (orderId: number) =>
      api.patch<Order>(`/api/v1/orders/${orderId}/confirm_payment`),
    onSuccess: (_, orderId) => {
      queryClient.invalidateQueries({ queryKey: ['orders', orderId] })
      queryClient.invalidateQueries({ queryKey: ['orders'] })
    },
  })
}

export function useUpdateOrderStatus() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, status }: { id: number; status: string }) =>
      api.patch<Order>(`/api/v1/orders/${id}/status`, { status }),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: ['orders', id] })
      queryClient.invalidateQueries({ queryKey: ['orders'] })
    },
  })
}

interface CounterOrderPayload {
  payment_method: PaymentMethod
  order_items_attributes: Array<{
    menu_item_id: number
    quantity: number
    unit_price: number
  }>
}

export function useCreateCounterOrder() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (payload: CounterOrderPayload) =>
      api.post<Order>('/api/v1/orders/counter', { order: payload }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] })
      queryClient.invalidateQueries({ queryKey: ['dashboard'] })
    },
  })
}

export function useCancelOrder() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, reason }: { id: number; reason?: string }) =>
      api.patch<Order>(`/api/v1/orders/${id}/cancel`, { cancellation_reason: reason }),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: ['orders', id] })
      queryClient.invalidateQueries({ queryKey: ['orders'] })
    },
  })
}
