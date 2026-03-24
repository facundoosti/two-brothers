import { useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'
import type { MenuItem } from '@/types/orders'

interface MenuItemPayload {
  name: string
  description?: string
  price: number
  category_id: number
  available?: boolean
  daily_stock?: number | null
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

export function useUploadMenuItemImage() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, file }: { id: number; file: File }) => {
      const form = new FormData()
      form.append('menu_item[image]', file)
      return api.patch_form<MenuItem>(`/api/v1/menu_items/${id}`, form)
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['categories'] }),
  })
}

export function useDeleteMenuItemImage() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: number) => api.delete<MenuItem>(`/api/v1/menu_items/${id}/image`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['categories'] }),
  })
}
