import { useState, useEffect, useRef, useCallback } from 'react'
import { MapPin, Loader2 } from 'lucide-react'

interface NominatimResult {
  place_id: number
  display_name: string
  lat: string
  lon: string
}

// Bounding box centrado en Dolores, Buenos Aires (west, north, east, south)
const DOLORES_VIEWBOX = '-58.1,-36.0,-57.2,-36.7'

function simplifyAddress(displayName: string): string {
  const parts = displayName.split(', ')
  const filtered = parts.filter(
    (p) => p !== 'Argentina' && !/^[A-Z]\d{4}$/.test(p),
  )
  return filtered.slice(0, 4).join(', ')
}

interface Props {
  value: string
  onChange: (address: string) => void
  placeholder?: string
}

export function AddressSearchInput({
  value,
  onChange,
  placeholder = 'Ingresá tu dirección en Dolores',
}: Props) {
  const [query, setQuery] = useState(value)
  const [results, setResults] = useState<NominatimResult[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [open, setOpen] = useState(false)
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const containerRef = useRef<HTMLDivElement>(null)

  // Close dropdown on outside click
  useEffect(() => {
    function onMouseDown(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false)
      }
    }
    document.addEventListener('mousedown', onMouseDown)
    return () => document.removeEventListener('mousedown', onMouseDown)
  }, [])

  const search = useCallback(async (q: string) => {
    setIsLoading(true)
    try {
      const params = new URLSearchParams({
        q: `${q}, Dolores, Buenos Aires`,
        format: 'json',
        limit: '5',
        countrycodes: 'ar',
        viewbox: DOLORES_VIEWBOX,
        bounded: '0',
        'accept-language': 'es',
      })
      const res = await fetch(
        `https://nominatim.openstreetmap.org/search?${params}`,
        { headers: { Accept: 'application/json' } },
      )
      const data: NominatimResult[] = await res.json()
      setResults(data)
      setOpen(data.length > 0)
    } catch {
      setResults([])
      setOpen(false)
    } finally {
      setIsLoading(false)
    }
  }, [])

  function handleInputChange(e: React.ChangeEvent<HTMLInputElement>) {
    const q = e.target.value
    setQuery(q)
    onChange(q) // free typing also updates the store

    if (debounceRef.current) clearTimeout(debounceRef.current)

    if (q.trim().length < 3) {
      setResults([])
      setOpen(false)
      return
    }

    debounceRef.current = setTimeout(() => search(q), 400)
  }

  function handleSelect(result: NominatimResult) {
    const address = simplifyAddress(result.display_name)
    setQuery(address)
    onChange(address)
    setResults([])
    setOpen(false)
  }

  return (
    <div ref={containerRef} className="relative">
      <div className="bg-(--color-surface) rounded-(--radius-lg) flex items-center gap-3 px-4 py-3 border border-(--color-border) focus-within:border-(--color-primary)/50 transition-colors">
        {isLoading ? (
          <Loader2 size={15} className="text-(--color-text-muted) shrink-0 animate-spin" />
        ) : (
          <MapPin size={15} className="text-(--color-text-muted) shrink-0" />
        )}
        <input
          type="text"
          value={query}
          onChange={handleInputChange}
          onFocus={() => results.length > 0 && setOpen(true)}
          placeholder={placeholder}
          className="bg-transparent flex-1 text-sm text-(--color-text-primary) placeholder:text-(--color-text-muted) outline-none"
          autoComplete="off"
        />
      </div>

      {open && (
        <ul className="absolute z-50 top-full mt-1.5 w-full bg-(--color-surface-elevated) border border-(--color-border) rounded-(--radius-lg) shadow-lg overflow-hidden">
          {results.map((r) => (
            <li key={r.place_id} className="border-b border-(--color-border) last:border-0">
              <button
                type="button"
                onMouseDown={(e) => e.preventDefault()} // prevent onBlur before click
                onClick={() => handleSelect(r)}
                className="w-full flex items-start gap-3 px-4 py-3 text-left hover:bg-(--color-surface) transition-colors"
              >
                <MapPin size={13} className="text-(--color-accent) shrink-0 mt-0.5" />
                <span className="text-sm text-(--color-text-primary) leading-snug">
                  {simplifyAddress(r.display_name)}
                </span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
