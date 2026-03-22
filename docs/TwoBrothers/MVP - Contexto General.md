---
proyecto: Two Brothers
tipo: MVP
industria: Gastronomía
estado: En definición
fecha_creacion: '2026-03-16'
tags:
  - mvp
  - gastronomia
  - rails
  - two-brothers
---

# Two Brothers — Contexto MVP

> App web responsive para la gestión integral de órdenes de un local de pollos al espiedo. Cubre desde el pedido online del cliente final hasta la gestión de cocina, mostrador, delivery y reportes.

---

## 📋 Tabla de Contenidos

- [[#1. Descripción del Proyecto]]
- [[#2. Autenticación y Roles]]
- [[#3. Requerimientos Funcionales por Rol]]
- [[#4. Identidad Visual]]
- [[#5. Diseño y Layout de Páginas]]
- [[#6. Arquitectura Técnica & Stack]]
- [[Reglas de Negocio|7. Reglas de Negocio →]]
- [[Flujos/Happy Path - Ciclo de una Orden|8. Happy Path — Ciclo de una Orden →]]

---

## 1. Descripción del Proyecto

| Campo | Detalle |
|---|---|
| **Nombre** | Two Brothers |
| **Rubro** | Gastronomía — Pollos al espiedo |
| **Tipo de app** | Web responsive (cliente específico) |
| **Etapa** | Idea / definición inicial |
| **Alcance MVP** | Pedidos online, mostrador, cocina, delivery, reportes |

### Objetivo principal
Digitalizar el flujo completo de órdenes del local: desde que el cliente hace un pedido (online o en mostrador) hasta que el repartidor lo entrega, con visibilidad en tiempo real para cocina y administración.

### Problema que resuelve
- Eliminación de órdenes tomadas en papel o de forma verbal
- Centralización del estado de cada pedido en tiempo real
- Trazabilidad completa del pedido (creación → cocina → entrega)
- Historial de ventas y reportes para el dueño

---

## 2. Autenticación y Roles

### 2.1 Autenticación ✅
- **Todos los usuarios** se autentican con **Google OAuth** (Google Sign-In)
- Una vez autenticado, el sistema asigna la vista y permisos según el **rol** del usuario
- El rol es asignado internamente por el administrador (no auto-seleccionable)

### 2.2 Roles del Sistema

| Rol | Descripción |
|---|---|
| `admin` | Acceso completo: órdenes, repartidores, envíos/retiros, dashboard, trackeo en tiempo real |
| `delivery` | Acceso a sus repartos asignados, reparto actual y funcionalidad de trackeo |
| `customer` | Crear órdenes, trackeo de su envío, historial de pedidos |

> 💡 No existe un rol de "cocinero" como usuario separado en el MVP. La vista de cocina (KDS) puede ser una pantalla sin login fija en el local, o accesible por el admin/operador.

### 2.3 Flujo de Autenticación
```
Usuario ingresa → Google OAuth → Callback → Sistema verifica rol en DB
        ↓                                              ↓
  Si no tiene rol                              Redirige a vista
  → Pantalla de "cuenta pendiente de activación"   según rol
```

---

## 3. Requerimientos Funcionales por Rol

> Estado: 🔲 Sin definir | 🟡 En discusión | ✅ Confirmado

### 3.1 Admin ✅

#### Dashboard
- ✅ Contador de órdenes del día (totales, en curso, completadas, canceladas)
- 🔲 Resumen de ventas del día (monto total)
- 🔲 Órdenes activas en tiempo real

#### Gestión de Órdenes
- 🔲 Listado de órdenes con filtros: fecha, estado, modalidad (envío / retiro)
- 🔲 Ver detalle de una orden
- 🔲 Cambiar estado de una orden manualmente
- 🔲 Crear orden manualmente (mostrador)
- 🔲 Cancelar orden con motivo

#### Gestión de Repartidores
- 🔲 Listado de repartidores activos
- 🔲 Asignar pedido a repartidor
- 🔲 Ver estado de cada repartidor (disponible / en reparto)

#### Envíos y Retiros
- 🔲 Filtrar órdenes por modalidad: delivery vs. retiro en local
- 🔲 Ver órdenes listas para despacho

#### Trackeo en Tiempo Real
- ✅ Ver en un mapa (o timeline) la ubicación/estado de un envío activo
- 🔲 Historial de movimientos de un reparto

#### Reportes
- 🔲 Ventas por período (diario, semanal, mensual)
- 🔲 Ítems más vendidos
- 🔲 Exportar a CSV

---

### 3.2 Repartidor ✅

#### Mis Repartos
- ✅ Lista de repartos asignados (pendientes y finalizados)
- 🔲 Ver detalle del pedido a entregar (dirección, ítems, datos del cliente)

#### Reparto Actual
- ✅ Vista del reparto en curso
- 🔲 Actualizar estado: `Aceptado → En camino → Entregado`
- 🔲 Registrar hora de salida y entrega

#### Trackeo del Reparto
- ✅ Funcionalidad de trackeo activo mientras tiene un reparto en curso
- 🔲 Geolocalización vía browser (Geolocation API)
- 🔲 Envío periódico de coordenadas al backend (via WebSocket o polling)

---

### 3.3 Usuario Final (Customer) ✅

#### Crear una Orden
- ✅ Ver menú con categorías e ítems
- 🔲 Seleccionar ítems y armar carrito
- 🔲 Elegir modalidad: delivery o retiro en local
- 🔲 Ingresar dirección de entrega (si es delivery)
- ✅ Pagar con **Mercado Pago**
- 🔲 Confirmación de la orden con número/código

#### Trackeo del Envío
- ✅ Seguimiento en tiempo real del estado de su pedido
- 🔲 Timeline de estados: Confirmado → En preparación → En camino → Entregado
- 🔲 Mapa con ubicación del repartidor (si aplica)

#### Historial de Pedidos
- ✅ Lista de órdenes anteriores del usuario
- 🔲 Ver detalle de cada pedido pasado
- 🔲 Repetir un pedido anterior (nice to have)

---

### 3.4 Notificaciones ✅
- **Canal:** Notificaciones web (Web Push Notifications / in-app)
- 🔲 Al cliente: cambio de estado de su pedido (confirmado, en camino, entregado)
- 🔲 Al repartidor: nuevo reparto asignado
- 🔲 Al admin: nueva orden recibida

---

## 4. Identidad Visual

### 4.1 Estilo General
| Atributo | Definición |
|---|---|
| **Personalidad** | Oscuro, moderno, sofisticado |
| **Tono** | Profesional pero cercano |
| **Referencia de estilo** | Dark UI con acentos de verde esmeralda y ámbar |
| **Librería de componentes** | Halo (Pencil) |

### 4.2 Paleta de Colores ✅

> Definida a partir del diseño en Pencil con la librería Halo. Tema oscuro.

| Rol | Token | HEX | Uso |
|---|---|---|---|
| **Fondo general** | `--background` | `#0D0F14` | Background de toda la app |
| **Superficie / Card** | `--card` | `#151820` | Cards, paneles, modales |
| **Superficie sidebar** | `--sidebar` | `#101319` | Sidebar de navegación |
| **Superficie elevada** | `--secondary` | `#1E2130` | Inputs, elementos sobre card |
| **Borde** | `--border` | `#252A35` | Divisores, bordes de cards |
| **Primario** | `--primary` | `#40C97F` | CTAs, nav activo, éxito, links |
| **Primario foreground** | `--primary-foreground` | `#0D0F14` | Texto sobre botón primario |
| **Texto principal** | `--foreground` | `#E8EAF0` | Títulos y cuerpo |
| **Texto secundario** | `--muted-foreground` | `#7A8099` | Subtítulos, metadata, placeholders |
| **Texto muted sidebar** | `--sidebar-foreground` | `#404560` | Labels de sección en nav |
| **Acento / Alerta** | `--warning` | `#F4A261` | Órdenes en curso, estados de espera |
| **Éxito bg** | `--color-success` | `#1A3D2B` | Fondo de badge éxito |
| **Éxito fg** | `--color-success-foreground` | `#40C97F` | Texto de badge éxito |
| **Warning bg** | `--color-warning` | `#3D2E10` | Fondo de badge advertencia |
| **Warning fg** | `--color-warning-foreground` | `#F4A261` | Texto de badge advertencia |
| **Error** | `--color-error-foreground` | `#E63946` | Errores, cancelaciones |
| **Nav activo bg** | — | `#1A2234` | Fondo item activo en sidebar |

### 4.3 Tipografía ✅

| Rol | Fuente | Peso | Tamaño base |
|---|---|---|---|
| **Display / Títulos grandes** | Inter | 700 (Bold) | 2rem+ |
| **Headings** | Inter | 600 (SemiBold) | 1.25–1.75rem |
| **Cuerpo** | Inter | 400 (Regular) | 1rem (16px) |
| **Labels / UI pequeño** | Inter | 500 (Medium) | 0.875rem |
| **Monoespaciado (códigos de orden)** | JetBrains Mono | 500 | 0.9rem |

> 💡 Fuentes vía Google Fonts. Inter para toda la UI, JetBrains Mono exclusivamente para números de orden y códigos.

### 4.4 Iconografía ✅
- **Lucide Icons** — alineado con la librería Halo de Pencil

### 4.5 Bordes, Radios y Sombras ✅
| Elemento | Radio | Sombra |
|---|---|---|
| Cards / Modales | `16px` | `0 10px 35px rgba(0,0,0,0.04)` |
| Botones / Inputs | `999px` (pill) | — |
| Badges / Pills | `999px` | — |
| Items sidebar activo | `8px` | — |
| Divisores | — | `border: 1px solid #252A35` |

---

## 5. Diseño y Layout de Páginas

> 🔲 Todas las vistas están pendientes de wireframe

### 5.1 Vistas públicas (Customer)
| Ruta | Vista | Descripción |
|---|---|---|
| `/` | Menú público | Categorías e ítems con precios |
| `/carrito` | Carrito | Resumen, datos y pago con Mercado Pago |
| `/pedido/:id` | Trackeo | Estado y seguimiento del pedido en tiempo real |
| `/historial` | Historial | Órdenes anteriores del usuario autenticado |

### 5.2 Panel Admin
| Ruta | Vista | Descripción |
|---|---|---|
| `/admin` | Dashboard | Contadores del día, órdenes activas |
| `/admin/ordenes` | Órdenes | Listado con filtros y cambio de estado |
| `/admin/repartidores` | Repartidores | Estado y asignación de repartos |
| `/admin/envios` | Envíos / Retiros | Órdenes por modalidad |
| `/admin/trackeo/:id` | Trackeo | Seguimiento en tiempo real de un envío |
| `/admin/menu` | Menú | ABM de categorías e ítems |
| `/admin/reportes` | Reportes | Gráficos y exportación |

### 5.3 Panel Repartidor
| Ruta | Vista | Descripción |
|---|---|---|
| `/delivery` | Mis repartos | Lista de repartos asignados |
| `/delivery/actual` | Reparto actual | Vista del reparto en curso con trackeo activo |

### 5.4 Principios de Layout
- **Mobile-first:** breakpoints Tailwind estándar (`sm`, `md`, `lg`, `xl`)
- Panel admin: **sidebar** en desktop, **bottom nav** en mobile
- App cliente: navegación simple top bar + footer
- Máximo ancho de contenido: `1280px` centrado
- Espaciado base: escala de 4px (Tailwind default)

---

## 6. Arquitectura Técnica & Stack

### 6.1 Arquitectura General
```
┌─────────────────────┐        ┌──────────────────────┐
│   Frontend (React)  │ ◄────► │   Backend (Rails API) │
│   Puerto: 3000      │  HTTP  │   Puerto: 4000        │
│   Vite + TypeScript │  WS    │   API mode            │
└─────────────────────┘        └──────────────┬────────┘
                                              │
                               ┌──────────────┼────────────┐
                               │              │            │
                         PostgreSQL        Redis       Sidekiq
                                         (cache/WS)   (jobs async)
```

### 6.2 Stack Principal ✅

| Capa | Tecnología | Notas |
|---|---|---|
| **Backend** | Ruby on Rails 8.x (API mode) | JSON API, sin assets propios |
| **Base de datos** | PostgreSQL | |
| **Frontend** | React + TypeScript | Vite como bundler |
| **Estilos** | Tailwind CSS v4 | |
| **State management** | Zustand | Estado global de UI (carrito, sesión, UI state) |
| **Data fetching** | TanStack Query (React Query v5) | Cache, polling, mutations, invalidación |
| **Jobs async** | Sidekiq + Redis | Notificaciones, reportes async |
| **Auth** | Google OAuth 2.0 | `omniauth-google-oauth2` en Rails |
| **Real-time notificaciones** | ActionCable (WebSockets) | Cambios de estado de órdenes |
| **Geolocalización** | Polling vía TanStack Query | `refetchInterval: 5000ms` — ver sección 6.4 |
| **Pagos** | Mercado Pago | SDK oficial, Checkout Pro o Checkout API |

### 6.3 Decisiones Pendientes

- 🔲 ¿TypeScript estricto o permisivo en el frontend?
- 🔲 ¿Plataforma de deploy? (Fly.io, Render, VPS propio)
- 🔲 ¿Web Push Notifications con service worker o solo notificaciones in-app?
- 🔲 ¿CORS configurado para dominio fijo o dinámico?

### 6.4 Estrategia de Geolocalización del Repartidor ✅

**Decisión:** Polling HTTP cada 5 segundos via TanStack Query (no WebSocket).

#### Flujo completo

```
[Repartidor — Browser]              [Rails API]              [Admin / Cliente]
        │                                │                         │
        │  navigator.geolocation         │                         │
        │  .watchPosition()              │                         │
        │  (dispara en cada movimiento)  │                         │
        │                                │                         │
        │  POST /api/delivery_locations  │                         │
        │  { lat, lng, assignment_id } ─►│ INSERT delivery_locations
        │                                │                         │
        │                                │◄── GET .../latest       │
        │                                │    cada 5s (TanStack)   │
        │                                │───────────────────────► │
        │                                │  { lat, lng, recorded_at }
        │                                │                actualiza mapa
```

#### Responsabilidades por capa

| Capa | Responsabilidad |
|---|---|
| **Repartidor (React)** | `watchPosition()` → POST a Rails en cada movimiento detectado |
| **Rails API** | `POST /delivery_locations` guarda; `GET .../latest` devuelve última posición |
| **Admin/Cliente (React)** | TanStack Query con `refetchInterval: 5000` consulta y actualiza mapa |

#### ¿Por qué polling y no WebSocket para geolocalización?

| | Polling (elegido) | WebSocket |
|---|---|---|
| **Complejidad** | Baja | Alta (canal, suscripción, reconexión) |
| **Latencia** | ~5s | Casi real-time |
| **Carga servidor** | Predecible | Conexión persistente por cliente |
| **Para GPS delivery** | ✅ Suficiente | Overkill |

> 💡 **ActionCable se reserva exclusivamente para notificaciones de cambio de estado de órdenes** (nueva orden, orden confirmada, lista para despacho, etc.) donde la reacción inmediata importa.

### 6.4 Estructura de Modelos (Borrador Inicial)

```ruby
User
  # Autenticación
  - provider: string        # "google"
  - uid: string             # Google UID
  - email: string
  - name: string
  - avatar_url: string
  - role: enum              # admin | delivery | customer
  - default_address: string # dirección de entrega por defecto (customers)

Order
  - user: references        # customer que hizo el pedido
  - created_by: references  # User admin/operador si fue creada desde mostrador
  - cancelled_by: references
  - cancelled_at: datetime
  - cancellation_reason: string
  - status: enum            # pending_payment | confirmed | preparing | ready | delivering | delivered | cancelled
  - modality: enum          # delivery | pickup
  - total: decimal
  - payment_method: enum    # cash | transfer
  - delivery_address: string # dirección específica de esta orden

OrderItem
  - order: references
  - menu_item: references
  - quantity: integer
  - unit_price: decimal
  - notes: string

MenuItem
  - category: references
  - name: string
  - description: text
  - price: decimal
  - available: boolean
  - image_url: string

Category
  - name: string
  - position: integer

DeliveryAssignment
  - order: references
  - user: references        # repartidor (role: delivery)
  - status: enum            # assigned | in_transit | delivered
  - assigned_at: datetime
  - departed_at: datetime
  - delivered_at: datetime

DeliveryLocation             # Trackeo en tiempo real
  - delivery_assignment: references
  - latitude: decimal
  - longitude: decimal
  - recorded_at: datetime

Setting                      # Configuración del local
  - key: string              # unique: daily_chicken_stock, mp_alias, store_address, etc.
  - value: string

DailyStock                   # Stock de pollos por día
  - date: date
  - total: integer           # configurado para ese día
  - used: integer            # se incrementa al confirmar cada orden
```

---

## 📝 Log de Decisiones

| Fecha | Decisión | Estado |
|---|---|---|
| 2026-03-16 | Creación inicial del documento | ✅ |
| 2026-03-16 | Auth: Google OAuth para todos los usuarios | ✅ |
| 2026-03-16 | Arquitectura: Rails API + React SPA separados | ✅ |
| 2026-03-16 | Pagos: Mercado Pago | ✅ |
| 2026-03-16 | Notificaciones: Web push / in-app (sin SMS ni WhatsApp) | ✅ |
| 2026-03-16 | Paleta oscura definida desde Pencil/Halo: fondo `#0D0F14`, primario `#40C97F`, acento `#F4A261` | ✅ |
| 2026-03-16 | Tipografía: Inter para toda la UI, JetBrains Mono para códigos de orden | ✅ |
| 2026-03-16 | Iconografía: Lucide Icons | ✅ |
| 2026-03-16 | Librería de componentes UI: Halo (Pencil) | ✅ |
| 2026-03-16 | Tema: Dark UI | ✅ |
| 2026-03-16 | Sin webhooks de MP en el MVP | ✅ |
| 2026-03-16 | Confirmación de pago: botón en panel admin | ✅ |
| 2026-03-16 | Checkout API de MP (usuario no abandona la app) | ✅ |
| 2026-03-16 | Medios de pago: tarjeta, efectivo, transferencia alias MP | ✅ |
| 2026-03-16 | Idempotencia en webhook MP: verificar estado previo antes de procesar | ✅ |
| 2026-03-16 | Librería de mapas: **mapcn** (MapLibre GL + shadcn/ui compatible) — tiles OpenStreetMap, sin API key | ✅ |

---

## ⏭️ Próximos Pasos

- [ ] Validar paleta de colores con el cliente
- [ ] Definir wireframes de las vistas principales
- [ ] Confirmar decisiones técnicas pendientes (deploy, notificaciones push)
- [ ] [[Flujos/Happy Path - Ciclo de una Orden|Happy path de una orden]] ✅ — revisar pendientes internos
- [ ] Definir contrato de API (endpoints REST entre Rails y React)
- [ ] Estimar effort por módulo
