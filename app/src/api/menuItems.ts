import { useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'
import type { MenuItem } from '@/types/orders'

interface MenuItemPayload {
  name: string
  description?: string
  price: number
  category_id: number
  available?: boolean
}

export function useCreateMenuItem() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (payload: MenuItemPayload) =>
      api.post<MenuItem>('/api/v1/menu_items', { menu_item: payload }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['categories'] }),
  })
}

export function useUpdateMenuItem() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, ...payload }: { id: number } & Partial<MenuItemPayload>) =>
      api.patch<MenuItem>(`/api/v1/menu_items/${id}`, { menu_item: payload }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['categories'] }),
  })
}

export function useDeleteMenuItem() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: number) => api.delete(`/api/v1/menu_items/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['categories'] }),
  })
}
