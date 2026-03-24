# Two Brothers — CLAUDE.md

App web responsive para la gestión integral de órdenes de un local gastronómico. Cubre desde el pedido online del cliente hasta cocina, delivery y reportes.

---

## Stack

| Capa | Tecnología |
|---|---|
| **Runtime** | Node 24+ (gestor: `n`) |
| **Bundler** | Vite 8 |
| **Frontend** | React 19 + TypeScript 5 (strict) |
| **Estilos** | Tailwind CSS v4 — sin `tailwind.config.js`, tokens en `@theme {}` dentro de `src/globals.css` |
| **Routing** | React Router v7 — `createBrowserRouter`, lazy routes con `Suspense` |
| **Data fetching** | TanStack Query v5 — `staleTime: 30s`, polling geoloc `refetchInterval: 5000` |
| **Estado global** | Zustand v5 |
| **Iconos** | Lucide React |
| **Path alias** | `@/` → `./src/` (configurado en `vite.config.ts` y `tsconfig.app.json`) |

**Instalación de dependencias:** usar `npm install` (el `.npmrc` tiene `legacy-peer-deps=true` por compatibilidad de `@tailwindcss/vite` con Vite 8).

---

## Estructura del Proyecto

```
src/
  features/
    auth/          # LoginPage (Google OAuth)
    customer/      # MenuPage, CartPage, OrderPage, HistoryPage, CustomerLayout
    admin/         # DashboardPage, OrdersPage, OrderDetailPage, DeliveryStaffPage,
                   # TrackingPage, MenuPage, ReportsPage, ShipmentsPage, AdminLayout
                   # components/AdminSidebar, AdminTopbar
    delivery/      # DeliveryHomePage, DeliveryCurrentPage, DeliveryLayout
  routes/
    router.tsx     # createBrowserRouter con lazy imports
  lib/
    utils.ts       # cn() helper
    status.ts      # ORDER_STATUS_LABEL/CLASSES, DELIVERY_STATUS_LABEL/CLASSES
  types/
    orders.ts      # OrderStatus, OrderModality, PaymentStatus, Order, OrderItem, etc.
  globals.css      # @import "tailwindcss" + @theme {} con todos los tokens
  App.tsx          # QueryClientProvider + Suspense + RouterProvider
  main.tsx
```

---

## Design System (Tailwind v4 tokens)

Definidos en `src/globals.css` dentro del bloque `@theme {}`:

| Token | Valor | Uso |
|---|---|---|
| `--color-background` | `#0D0F14` | Fondo general |
| `--color-surface` | `#151820` | Cards, paneles |
| `--color-surface-elevated` | `#1E2130` | Inputs, elementos sobre card |
| `--color-sidebar` | `#101319` | Sidebar |
| `--color-primary` | `#40C97F` | CTAs, nav activo, éxito |
| `--color-accent` | `#F4A261` | Órdenes en curso, warnings |
| `--color-text-primary` | `#E8EAF0` | Títulos y cuerpo |
| `--color-text-secondary` | `#7A8099` | Subtítulos, metadata |
| `--color-text-muted` | `#404560` | Labels de sección |
| `--color-border` | `#252A35` | Bordes de cards, divisores |

**Tipografía:** Inter para toda la UI, JetBrains Mono para números de orden y códigos.
**Iconos:** Lucide React.
**Radios:** Cards `16px`, botones/inputs pill (`999px`), badges pill.

---

## Rutas

### Cliente
| Ruta | Componente |
|---|---|
| `/` | `CustomerMenuPage` |
| `/carrito` | `CustomerCartPage` |
| `/pedido/:id` | `CustomerOrderPage` |
| `/historial` | `CustomerHistoryPage` |

### Admin
| Ruta | Componente |
|---|---|
| `/admin` | `AdminDashboardPage` |
| `/admin/ordenes` | `AdminOrdersPage` |
| `/admin/ordenes/:id` | `AdminOrderDetailPage` |
| `/admin/repartidores` | `AdminDeliveryStaffPage` |
| `/admin/envios` | `AdminShipmentsPage` |
| `/admin/trackeo/:id` | `AdminTrackingPage` |
| `/admin/menu` | `AdminMenuPage` |
| `/admin/reportes` | `AdminReportsPage` |

### Repartidor
| Ruta | Componente |
|---|---|
| `/delivery` | `DeliveryHomePage` |
| `/delivery/actual` | `DeliveryCurrentPage` |

---

## Estados de una Orden

```
pending_payment → confirmed → preparing → ready → delivering → delivered
                                                    ↑ se asigna repartidor aquí
Cancelable desde: pending_payment, confirmed, preparing
No cancelable desde: ready, delivering, delivered
```

| Estado | Label ES |
|---|---|
| `pending_payment` | Pendiente de pago |
| `confirmed` | Confirmada |
| `preparing` | En preparación |
| `ready` | Lista |
| `delivering` | En camino |
| `delivered` | Entregada |
| `cancelled` | Cancelada |

---

## Roles del Sistema

| Rol | Acceso |
|---|---|
| `admin` | Panel completo: órdenes, repartidores, trackeo, menú, reportes |
| `delivery` | Sus repartos asignados y reparto actual |
| `customer` | Menú público, carrito, trackeo de su pedido, historial |

Autenticación: **Google OAuth 2.0** para todos los usuarios. El rol es asignado internamente por el admin.

---

## Reglas de Negocio Clave

- **Creación y confirmación de pago:** el customer crea la orden → nace en `pending_payment`. El admin verifica que el pago fue recibido (efectivo o transferencia al alias CVU) y presiona "Confirmar pago" → pasa a `confirmed`. Recién desde `confirmed` el admin puede avanzar los demás estados.
- **Stock diario:** 100 unidades/día por defecto (configurable). Resetea a las 00:00 via Solid Queue.
- **Máximo por orden:** 4 unidades.
- **Stock se descuenta** al confirmar (`confirmed`). Se devuelve si se cancela desde `confirmed`.
- **Horario:** Jueves a Domingo, 20:00–00:00. Fuera de horario: menú visible pero creación de órdenes bloqueada.
- **Solo admin/operador** puede cancelar órdenes (hasta `confirmed` inclusive).
- **Orden desde mostrador** nace directamente en `confirmed` (pago presencial).
- **Pagos:** efectivo en mano o transferencia al alias CVU de Mercado Pago. **Sin integración de pago online.** El admin confirma el cobro manualmente desde el panel.

## Flujo de estados de una orden (responsables)

| Transición | Quién lo hace | Acción en el frontend |
|---|---|---|
| `pending_payment → confirmed` | Admin | Botón "Confirmar pago" en detalle de orden |
| `confirmed → preparing` | Admin | Botón "Iniciar preparación" |
| `preparing → ready` | Admin | Botón "Marcar lista" |
| `ready → delivering` | Admin | Botón "Despachar" |
| `delivering → delivered` | Repartidor | Botón "Marcar entregado" en `/delivery/actual` |
| cancelar (cualquier estado cancelable) | Admin (solo) | Botón "Cancelar" en detalle de orden |

**El repartidor NO puede cancelar ni avanzar estados de la orden, solo puede marcarla como entregada.**

---

## Estrategia Real-time

| Mecanismo | Uso |
|---|---|
| **ActionCable (WebSocket)** | Notificaciones de cambio de estado de órdenes |
| **Polling HTTP cada 5s** (TanStack Query `refetchInterval`) | Geolocalización del repartidor |

El repartidor envía su posición vía `POST /api/delivery_locations` al detectar movimiento con `watchPosition()`. Admin/cliente consultan `GET /api/delivery_locations/:id/latest` cada 5s.

---

## Backend (referencia)

- **Ruby on Rails 8.x** en API mode + PostgreSQL + Redis + Sidekiq
- Repositorio separado (este repo es solo el frontend)
- Modelos principales: `User`, `Order`, `OrderItem`, `MenuItem`, `Category`, `DeliveryAssignment`, `DeliveryLocation`, `Setting`, `DailyStock`

---

## Convenciones de Código

- TypeScript estricto: `noUnusedLocals: true`, `noUnusedParameters: true` — todos los imports deben usarse.
- Cada ruta es lazy-loaded con `React.lazy()` para code splitting.
- Tailwind v4: usar variables CSS como `text-(--color-text-primary)`, no hardcodear colores.
- Páginas admin usan `<AdminTopbar>` con props `title`, `subtitle?` (`React.ReactNode`), `actions?`.
- `cn()` en `@/lib/utils` para clases condicionales.
- `ORDER_STATUS_LABEL` y `ORDER_STATUS_CLASSES` en `@/lib/status` para badges de estado.
