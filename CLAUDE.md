# Two Brothers — Monorepo

Este repositorio contiene dos proyectos separados:

| Carpeta | Rol | Stack |
|---|---|---|
| `app/` | **Frontend** | React 19 + TypeScript + Vite + Tailwind CSS v4 |
| `api/` | **Backend** | Ruby on Rails 8.x (API mode) + PostgreSQL + Solid Queue/Cache/Cable |

Cada carpeta tiene su propio `CLAUDE.md` con instrucciones específicas del proyecto.

## Decisiones técnicas transversales

| Decisión | Detalle |
|---|---|
| **Mapas** | mapcn (MapLibre GL + shadcn), tiles OpenStreetMap, sin API key |
| **Geocodificación** | `geocoder` gem con Nominatim (OpenStreetMap) — sin API key. Convierte `delivery_address` a `latitude`/`longitude` en el modelo `Order` |
| **Geolocalización repartidor** | Polling HTTP cada 5s via TanStack Query (`refetchInterval: 5000`) — no WebSocket |
