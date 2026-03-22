import { useEffect } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { getCableConsumer } from '@/lib/cable'

interface OrderStatusPayload {
  id: number
  status: string
}

/**
 * Subscribes to real-time order status updates via ActionCable.
 *
 * - With `orderId`: streams a single order (customer order tracking, admin order detail).
 * - Without `orderId`: streams all order changes (admin list/dashboard — server rejects if not admin).
 */
export function useOrderStatus(orderId?: number | string) {
  const queryClient = useQueryClient()

  useEffect(() => {
    const params = orderId
      ? { channel: 'OrderStatusChannel', order_id: orderId }
      : { channel: 'OrderStatusChannel' }

    const subscription = getCableConsumer().subscriptions.create(params, {
      received(data: OrderStatusPayload) {
        // Always invalidate the specific order
        queryClient.invalidateQueries({ queryKey: ['order', String(data.id)] })
        // Invalidate list + dashboard so counts and tables update
        queryClient.invalidateQueries({ queryKey: ['orders'] })
        queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      },
    })

    return () => subscription.unsubscribe()
  }, [orderId, queryClient])
}
