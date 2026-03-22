import { createConsumer } from '@rails/actioncable'
import { useAuthStore } from '@/store/authStore'

const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:4000'

let consumer: ReturnType<typeof createConsumer> | null = null

export function getCableConsumer() {
  if (!consumer) {
    const token = useAuthStore.getState().token
    consumer = createConsumer(`${API_URL}/cable?token=${token}`)
  }
  return consumer
}

export function disconnectCable() {
  consumer?.disconnect()
  consumer = null
}
