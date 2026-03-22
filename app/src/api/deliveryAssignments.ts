import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'
import type { DeliveryAssignmentWithOrder } from '@/types/orders'

interface AssignmentsResponse {
  data: DeliveryAssignmentWithOrder[]
  pagy: {
    page: number
    pages: number
    count: number
    limit: number
    prev: number | null
    next: number | null
  }
}

export function useDeliveryAssignments() {
  return useQuery({
    queryKey: ['delivery_assignments'],
    queryFn: () => api.get<AssignmentsResponse>('/api/v1/delivery_assignments'),
  })
}

export function useCreateDeliveryAssignment() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ order_id, user_id }: { order_id: number; user_id: number }) =>
      api.post<DeliveryAssignmentWithOrder>('/api/v1/delivery_assignments', { order_id, user_id }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['delivery_assignments'] })
      queryClient.invalidateQueries({ queryKey: ['orders'] })
    },
  })
}

export function useUpdateAssignmentStatus() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, status }: { id: number; status: 'in_transit' | 'delivered' }) =>
      api.patch<DeliveryAssignmentWithOrder>(`/api/v1/delivery_assignments/${id}/status`, {
        status,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['delivery_assignments'] })
      queryClient.invalidateQueries({ queryKey: ['orders'] })
    },
  })
}
