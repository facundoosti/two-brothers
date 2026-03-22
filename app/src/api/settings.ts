import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'

export interface Setting {
  key: string
  value: string | null
}

export type SettingsMap = Record<string, string>

function toMap(settings: Setting[]): SettingsMap {
  return Object.fromEntries(settings.map((s) => [s.key, s.value ?? '']))
}

export function useSettings() {
  return useQuery({
    queryKey: ['settings'],
    queryFn: async () => {
      const data = await api.get<Setting[]>('/api/v1/settings')
      return toMap(data)
    },
  })
}

export function useUpdateSettings() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (settings: SettingsMap) =>
      api.patch('/api/v1/settings', { settings }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['settings'] })
    },
  })
}
