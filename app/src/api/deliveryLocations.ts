import { useMutation, useQuery } from '@tanstack/react-query'
import { api } from '@/lib/api'
import type { DeliveryLocation } from '@/types/orders'

interface CreateLocationParams {
  delivery_assignment_id: number
  latitude: number
  longitude: number
  recorded_at: string
}

export function useCreateDeliveryLocation() {
  return useMutation({
    mutationFn: (params: CreateLocationParams) =>
      api.post<DeliveryLocation>('/api/v1/delivery_locations', params),
  })
}

export function useLatestLocation(assignmentId: number | string | undefined) {
  return useQuery({
    queryKey: ['delivery_locations', assignmentId],
    queryFn: () =>
      api.get<DeliveryLocation>(
        `/api/v1/delivery_assignments/${assignmentId}/latest_location`
      ).catch((err: Error & { status?: number }) => {
        if (err.status === 404) return null
        throw err
      }),
    enabled: !!assignmentId,
    refetchInterval: 5_000,
  })
}
