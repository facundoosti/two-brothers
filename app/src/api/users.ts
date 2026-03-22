import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'
import type { User, UserRole, UserStatus } from '@/types/users'

interface PagyMeta {
  page: number
  pages: number
  count: number
  limit: number
  prev: number | null
  next: number | null
}

interface UsersResponse {
  data: User[]
  pagy: PagyMeta
}

interface UsersFilters {
  role?: UserRole
  q?: string
  page?: number
}

export function useUsers(filters: UsersFilters = {}) {
  const params = new URLSearchParams()
  if (filters.role) params.set('role', filters.role)
  if (filters.q) params.set('q', filters.q)
  if (filters.page) params.set('page', String(filters.page))

  const query = params.toString()
  return useQuery({
    queryKey: ['users', filters],
    queryFn: () => api.get<UsersResponse>(`/api/v1/users${query ? `?${query}` : ''}`),
  })
}

export function useUpdateUser() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, role, status }: { id: number; role?: UserRole; status?: UserStatus }) =>
      api.patch<User>(`/api/v1/users/${id}`, { user: { role, status } }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
    },
  })
}
