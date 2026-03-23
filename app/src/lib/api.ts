import { useAuthStore } from '@/store/authStore'

const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:4000'

async function request<T>(path: string, options?: RequestInit & { isForm?: boolean }): Promise<T> {
  const token = useAuthStore.getState().token
  const { isForm, ...fetchOptions } = options ?? {}

  const res = await fetch(`${API_URL}${path}`, {
    ...fetchOptions,
    headers: {
      ...(!isForm && { 'Content-Type': 'application/json' }),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(fetchOptions.headers ?? {}),
    },
  })

  if (res.status === 401) {
    useAuthStore.getState().clearAuth()
    window.location.href = '/login'
    throw new Error('No autorizado')
  }

  if (res.status === 204) return undefined as T

  const data = await res.json()

  if (!res.ok) {
    throw new Error(data.error ?? `Error ${res.status}`)
  }

  return data as T
}

export const api = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, body?: unknown) =>
    request<T>(path, { method: 'POST', body: JSON.stringify(body) }),
  patch: <T>(path: string, body?: unknown) =>
    request<T>(path, { method: 'PATCH', body: JSON.stringify(body) }),
  patch_form: <T>(path: string, body: FormData) =>
    request<T>(path, { method: 'PATCH', body, isForm: true }),
  delete: <T>(path: string) => request<T>(path, { method: 'DELETE' }),
}

export const apiUrl = (path: string) => `${API_URL}${path}`
