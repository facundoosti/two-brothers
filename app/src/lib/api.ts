import { useAuthStore } from '@/store/authStore'

/**
 * URL base de la API.
 *
 * En desarrollo con subdominios (lvh.me), la API corre en el mismo host
 * que el frontend pero en puerto diferente. Derivamos el host del browser
 * para que el subdominio (tenant) viaje automáticamente en cada request.
 *
 * Ejemplos:
 *   tastychicken.lvh.me:5173 → http://tastychicken.lvh.me:3000
 *   localhost:5173           → http://localhost:3000
 *
 * En producción se puede sobreescribir con VITE_API_URL.
 */
function buildApiUrl(): string {
  if (import.meta.env.VITE_API_URL) {
    return import.meta.env.VITE_API_URL
  }

  const { protocol, hostname } = window.location
  const port = import.meta.env.VITE_API_PORT ?? '3000'
  return `${protocol}//${hostname}:${port}`
}

const API_URL = buildApiUrl()

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
    const err = new Error(data.error ?? `Error ${res.status}`) as Error & { status: number }
    err.status = res.status
    throw err
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
