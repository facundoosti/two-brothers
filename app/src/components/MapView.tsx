import { useEffect, useRef } from 'react'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'
import { cn } from '@/lib/utils'

export type MarkerKind = 'origin' | 'delivery' | 'destination'

export interface MapMarkerDef {
  lngLat: [number, number]
  kind: MarkerKind
  tooltip?: string
}

interface MapViewProps {
  center: [number, number]
  zoom?: number
  markers?: MapMarkerDef[]
  /** Fetch and draw the real bike route between these two points via OSRM */
  routeFrom?: [number, number]
  routeTo?: [number, number]
  className?: string
}

const DARK_STYLE: maplibregl.StyleSpecification = {
  version: 8,
  glyphs: 'https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf',
  sources: {
    carto: {
      type: 'raster',
      tiles: [
        'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
        'https://b.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
        'https://c.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
        'https://d.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
      ],
      tileSize: 256,
      attribution:
        '©<a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors ©<a href="https://carto.com/">CARTO</a>',
    },
  },
  layers: [{ id: 'carto-tiles', type: 'raster', source: 'carto' }],
}

const MARKER_CONFIG: Record<MarkerKind, { bg: string; border: string; size: number }> = {
  origin:      { bg: '#40C97F', border: '#ffffff', size: 14 },
  delivery:    { bg: '#40C97F', border: '#0D0F14', size: 16 },
  destination: { bg: '#9B5CF6', border: '#ffffff', size: 14 },
}

function buildMarkerEl(kind: MarkerKind): HTMLElement {
  const cfg = MARKER_CONFIG[kind]
  const el = document.createElement('div')
  el.style.width = `${cfg.size}px`
  el.style.height = `${cfg.size}px`
  el.style.background = cfg.bg
  el.style.border = `2.5px solid ${cfg.border}`
  el.style.borderRadius = '50%'
  el.style.boxShadow =
    kind === 'delivery'
      ? `0 0 0 4px rgba(64,201,127,0.25), 0 2px 8px rgba(0,0,0,0.7)`
      : `0 2px 6px rgba(0,0,0,0.6)`
  return el
}

async function fetchBikeRoute(
  from: [number, number],
  to: [number, number],
  signal: AbortSignal,
): Promise<[number, number][] | null> {
  const url =
    `https://router.project-osrm.org/route/v1/car/` +
    `${from[0]},${from[1]};${to[0]},${to[1]}` +
    `?overview=full&geometries=geojson`
  try {
    const res = await fetch(url, { signal })
    const data = await res.json()
    return data.routes?.[0]?.geometry?.coordinates ?? null
  } catch {
    return null
  }
}

export default function MapView({
  center,
  zoom = 14,
  markers = [],
  routeFrom,
  routeTo,
  className,
}: MapViewProps) {
  const containerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!containerRef.current) return

    const controller = new AbortController()

    const map = new maplibregl.Map({
      container: containerRef.current,
      style: DARK_STYLE,
      center,
      zoom,
      attributionControl: false,
    })

    map.addControl(new maplibregl.AttributionControl({ compact: true }), 'bottom-right')

    map.on('load', async () => {
      // Bike route via OSRM
      if (routeFrom && routeTo) {
        const coords = await fetchBikeRoute(routeFrom, routeTo, controller.signal)
        if (coords && !controller.signal.aborted) {
          map.addSource('route', {
            type: 'geojson',
            data: {
              type: 'Feature',
              geometry: { type: 'LineString', coordinates: coords },
              properties: {},
            },
          })
          // Subtle shadow layer
          map.addLayer({
            id: 'route-shadow',
            type: 'line',
            source: 'route',
            paint: {
              'line-color': '#000000',
              'line-width': 6,
              'line-opacity': 0.3,
              'line-blur': 3,
            },
          })
          // Main route line
          map.addLayer({
            id: 'route',
            type: 'line',
            source: 'route',
            paint: {
              'line-color': '#40C97F',
              'line-width': 3.5,
              'line-opacity': 0.9,
            },
          })
        }
      }

      if (controller.signal.aborted) return

      // Markers
      for (const m of markers) {
        const el = buildMarkerEl(m.kind)
        const marker = new maplibregl.Marker({ element: el }).setLngLat(m.lngLat).addTo(map)

        if (m.tooltip) {
          marker.setPopup(
            new maplibregl.Popup({ offset: 16, closeButton: false }).setText(m.tooltip),
          )
          el.addEventListener('mouseenter', () => marker.getPopup()?.addTo(map))
          el.addEventListener('mouseleave', () => marker.getPopup()?.remove())
        }
      }
    })

    return () => {
      controller.abort()
      map.remove()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return <div ref={containerRef} className={cn('w-full h-full', className)} />
}
