/**
 * Detecta el tenant activo desde el subdominio del browser.
 *
 * Ejemplos:
 *   tastychicken.lvh.me:5173     → "tastychicken"
 *   tastychicken.two-brothers.shop → "tastychicken"
 *   lvh.me:5173                  → null  (landing / sin tenant)
 *   localhost:5173               → null  (dev sin tenant)
 */
export function getCurrentTenant(): string | null {
  const hostname = window.location.hostname
  const parts = hostname.split('.')

  // localhost o IP → sin subdominio
  if (parts.length < 2) return null

  // "lvh.me" o "two-brothers.shop" → sin subdominio (solo 2 partes base)
  // "tastychicken.lvh.me" → 3 partes → tenant = "tastychicken"
  if (parts.length < 3) return null

  const subdomain = parts[0]

  // Subdominos reservados que no son tenants
  const reserved = ['www', 'api', 'admin']
  if (reserved.includes(subdomain)) return null

  return subdomain
}

export function hasTenant(): boolean {
  return getCurrentTenant() !== null
}

/**
 * URL base de la API en el dominio raíz (sin subdominio).
 * Se usa para iniciar el flujo OAuth, que siempre debe ocurrir en el dominio principal
 * para evitar agregar cada subdominio a Google Cloud Console.
 *
 * Desarrollo:  empresa.lvh.me:5173 → http://lvh.me:3000
 * Producción:  usa VITE_API_URL directamente (ya apunta al dominio raíz)
 */
export function getBaseApiUrl(): string {
  if (import.meta.env.VITE_API_URL) return import.meta.env.VITE_API_URL

  const { protocol, hostname } = window.location
  const parts = hostname.split('.')
  // Quitar el subdominio si existe (3+ partes: empresa.lvh.me)
  const baseHost = parts.length >= 3 ? parts.slice(1).join('.') : hostname
  const port = import.meta.env.VITE_API_PORT ?? '3000'
  return `${protocol}//${baseHost}:${port}`
}
