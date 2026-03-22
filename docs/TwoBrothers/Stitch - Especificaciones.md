# Two Brothers — Especificaciones de Diseño (Stitch)

> Documento de referencia para la generación y edición de pantallas en Stitch.
> Cubre el flujo cliente mobile: **Login · Cart · Checkout · Profile · Order Confirm**

Última actualización: 2026-03-22

---

## 1. Design System

### 1.1 Filosofía Visual — "The Culinary Noir"

UI editorial y de alta gama. El local vende pollos al espiedo como producto premium, no como fast food. La app debe transmitir eso. Claves:

- **Asimetría intencional:** texto alineado a izquierda, imágenes que rompen la grilla
- **Profundidad tonal:** separación de secciones solo por cambios de color de fondo, nunca con bordes
- **Glassmorphism:** barras de navegación con `background @ 70% opacity + backdrop-blur 20px`
- **Espacio:** mucho breathing room — `spacing-12` a `spacing-16` entre secciones

### 1.2 Tokens de Color

| Token | HEX | Uso |
|---|---|---|
| `background` | `#111318` | Fondo base de toda la app |
| `surface-container` | `#1e1f25` | Cards primarias |
| `surface-container-low` | `#1a1b21` | Inputs, elementos sobre card |
| `surface-container-lowest` | `#0c0e13` | "The Ticket" — resúmenes de orden |
| `surface-bright` | `#37393f` | Estados activos, elevación |
| `primary` | `#40c97f` | Color principal — CTAs, estados activos, éxito |
| `primary-light` | `#61e698` | Gradiente inicio para botones CTA |
| `on-primary` | `#00391d` | Texto sobre botón primario |
| `secondary / amber` | `#F4A261` | Estados pending, advertencias, timelines |
| `on-surface` | `#e2e2e9` | Texto principal |
| `on-surface-variant` | `#bccabd` | Texto muted, subtítulos, placeholders |
| `outline-variant` | `#3d4a40` | Ghost borders @ 15% opacity (solo accesibilidad) |
| `error` | `#ffb4ab` | Errores, cancelaciones |

### 1.3 Tipografía

| Nivel | Fuente | Peso | Tamaño | Uso |
|---|---|---|---|---|
| Display-LG | Inter | 700 Bold | 3.5rem | Titulares hero |
| Headline-SM | Inter | 600 SemiBold | 1.5rem | Headers de sección |
| Title-MD | Inter | 600 SemiBold | 1.125rem | Nombres de ítems, cards |
| Body-LG | Inter | 400 Regular | 1rem | Texto descriptivo |
| Label-MD | **JetBrains Mono** | 500 Medium | 0.75rem | Precios, códigos de orden, timestamps |

> **Regla:** Los precios y códigos de orden SIEMPRE van en JetBrains Mono.

### 1.4 Bordes y Radios

| Elemento | Radio |
|---|---|
| Cards | `16px` |
| Botones / Inputs | `999px` (pill) |
| Badges / Tags | `999px` |
| Imágenes en listas | `12px` |

### 1.5 Botones

| Tipo | Estilo |
|---|---|
| **Primary** | Pill, gradiente lineal `#61e698 → #40c97f` a 135°, texto `#00391d` bold |
| **Secondary** | Pill, fondo `#1e1f25`, sin borde, texto `#e2e2e9` |
| **Ghost** | Pill, fondo transparente, texto `#bccabd`, subrayado solo en hover |

### 1.6 Reglas Estrictas

- ❌ **Nunca** usar `#000000` — usar `#111318` como negro
- ❌ **Nunca** usar bordes 1px sólidos para separar contenido
- ❌ **Nunca** radios de 4px u 8px — solo `16px` o `999px`
- ✅ Separar contenido únicamente con cambios de `background-color` y `spacing`
- ✅ Iconos Lucide, stroke de 2px, monocromáticos (`#bccabd`), primario cuando activos

---

## 2. Pantallas del Flujo Cliente

---

### 2.1 Login — `/login`

**Dispositivo:** Mobile (390px)
**Ruta:** `/login`
**Propósito:** Punto de entrada a la app. Google OAuth único método.

#### Flujo de autenticación
```
Usuario abre app
  → no autenticado → /login
  → autenticado sin rol → /login con mensaje "cuenta pendiente"
  → autenticado con rol customer → / (menú)
```

#### Layout

**Zona superior (60% de pantalla) — Hero editorial:**
- Imagen atmosférica de pollos al espiedo, fuego, humo — sangra borde a borde
- Overlay gradiente oscuro de abajo hacia arriba (transparente → `#111318`)
- Sobre la imagen:
  - Wordmark **"Two Brothers"** Inter Bold, blanco, tamaño grande
  - Tagline `"Pollos al espiedo · Desde el barrio"` en `#bccabd`, 14px
  - Acento decorativo ámbar (`#F4A261`) — forma geométrica o glow detrás del texto

**Zona inferior (40%) — Card de acceso:**
- Fondo `#1e1f25`, esquinas superiores redondeadas `24px`
- Título `"Bienvenido"` Inter SemiBold 24px, blanco
- Subtexto muted `"Ingresá con tu cuenta de Google para hacer tu pedido"` 14px
- **Botón Google OAuth:** pill, fondo blanco, logo Google (colores), texto `"Continuar con Google"` Inter Medium gris oscuro, ancho completo
- Texto legal muted 12px: `"Al ingresar aceptás nuestros términos y condiciones"`
- Safe area padding inferior

#### Estados
| Estado | Comportamiento |
|---|---|
| Default | Layout descrito arriba |
| Loading (post-click) | Spinner sobre el botón, deshabilitado |
| Error OAuth | Toast / chip rojo debajo del botón |
| Cuenta pendiente | Banner ámbar: `"Tu cuenta está pendiente de activación. Contactate con el local."` |

---

### 2.2 Cart — `/carrito`

**Dispositivo:** Mobile (390px)
**Ruta:** `/carrito`
**Propósito:** Revisión del carrito antes de confirmar el pedido.

#### Reglas de negocio
- Máximo **4 pollos por orden**
- Solo disponible en horario de atención (Jue–Dom, 20:00–00:00)
- Stock validado al confirmar, no al agregar al carrito
- Dirección del perfil se sugiere por defecto (editable por orden)

#### Layout

**Topbar (glassmorphism):**
- `←` Volver (izquierda)
- `"Tu Carrito"` centered
- Badge verde con cantidad de ítems (derecha)

**Lista de ítems (fondo `#111318`, sin separadores, `spacing-6` entre items):**

Cada ítem:
```
[ Imagen 64×64 r-12px ] | Nombre ítem (Title-MD blanco)
                         | Variante / descripción (muted 13px)
                         | Precio en JetBrains Mono (#40c97f)
                         | [−] cantidad [+] (pill secundario)
```
- Botón eliminar ítem (ícono trash, muted, extremo derecho)
- Máximo visual: 4 ítems — si hay más, scroll

**Sección Modalidad (card `#1e1f25`, `r-16px`):**
- Label `"¿Cómo querés recibirlo?"` uppercase muted 11px
- Toggle pill: `"Delivery"` | `"Retiro en local"` — activo: fondo primary verde
- **Si Delivery:** input dirección pill (`#1a1b21`, ícono pin izquierda, placeholder `"Dirección de entrega"`)
  - Sugerencia: chip clickeable `"Usar: Av. Corrientes 1234 →"` (dirección del perfil)
- **Si Retiro:** texto muted `"Retirás en: San Martín 456, Dolores"` (dirección del local)

**Sección Medio de Pago (card `#1e1f25`, `r-16px`):**
- Label `"Medio de pago"` uppercase muted 11px
- Dos opciones en fila:
  - Card `"Efectivo"` — ícono billete, seleccionable
  - Card `"Transferencia MP"` — ícono teléfono/transfer, seleccionable
- Seleccionado: ghost border `#40c97f` al 40% + fondo ligeramente más claro

**Resumen — "The Ticket" (card `#0c0e13`, `r-16px`):**
- Header `"Resumen"` Inter SemiBold blanco
- Líneas en JetBrains Mono:
  ```
  2× Pollo Entero          $5.200
  Envío                      $500
  ─────────────────────────────
  Total                    $5.700
  ```
- `Total` en primary verde, mayor tamaño

**CTA Sticky (encima del safe area):**
- Botón primary pill gradiente, ancho completo: `"Confirmar pedido"`
- Glow ambiental verde detrás del botón
- Deshabilitado si: carrito vacío, sin dirección (delivery), fuera de horario

#### Estados del Carrito
| Estado | UI |
|---|---|
| Carrito vacío | Ilustración + texto `"Todavía no agregaste nada"` + CTA `"Ver menú"` |
| Fuera de horario | Banner ámbar: `"Estamos cerrados. Volvemos el Jueves a las 20:00 hs."` — CTA deshabilitado |
| Sin stock | Banner rojo: `"Se agotaron los pollos por hoy"` — CTA deshabilitado |

---

### 2.3 Checkout — modal / step dentro de `/carrito`

**Dispositivo:** Mobile (390px)
**Propósito:** Confirmación final antes de crear la orden. Bottom sheet sobre el carrito.

> El checkout no es una ruta separada — es un **bottom sheet modal** que aparece al presionar "Confirmar pedido" en el carrito.

#### Layout (Bottom Sheet, `#1e1f25`, esquinas `24px` arriba)

**Header:**
- Handle pill gris en el tope
- `"Confirmar pedido"` Inter SemiBold 18px blanco
- `✕` cerrar (derecha)

**Resumen compacto (card `#0c0e13`, JetBrains Mono):**
```
2× Pollo Entero .......... $5.200
Envío .................... $500
Total .................... $5.700
```

**Dirección confirmada (si delivery):**
- Ícono pin + dirección + botón `"Editar"` text link muted

**Medio de pago confirmado:**
- Ícono + `"Efectivo"` o `"Transferencia a TWOBROTHERS.MP"`

**Instrucción de pago (según medio):**

*Efectivo:*
> "Pagás en efectivo al recibir el pedido. El repartidor te cobrará en el momento."

*Transferencia:*
> "Alias: **TWOBROTHERS.MP** · Monto: **$5.700**
> Realizá la transferencia antes de que el local confirme tu pedido."

**CTAs:**
- Primary pill: `"Hacer el pedido"` — verde gradiente
- Ghost pill: `"Cancelar"`

#### Comportamiento
- Al presionar `"Hacer el pedido"`:
  1. Loading spinner en el botón
  2. `POST /api/v1/orders`
  3. Si OK → navegar a Order Confirm `/pedido/:id`
  4. Si error → toast con mensaje de error

---

### 2.4 Profile — `/perfil`

**Dispositivo:** Mobile (390px)
**Ruta:** `/perfil`
**Propósito:** Ver datos del usuario, gestionar dirección de entrega por defecto, historial de pedidos.

#### Acceso
- Desde el topbar del menú o carrito (ícono avatar)

#### Layout

**Header (fondo `#111318`):**
- Avatar circular del usuario (foto Google OAuth o iniciales)
- Nombre completo Inter Bold 20px blanco
- Email muted 14px
- Badge de rol: `"Cliente"` pill muted

**Sección Dirección por Defecto (card `#1e1f25`, `r-16px`):**
- Label `"Dirección de entrega"` uppercase muted 11px
- Si tiene dirección guardada:
  - Ícono pin + dirección blanca
  - Botón `"Editar"` (text link verde)
- Si no tiene:
  - `"Sin dirección guardada"` muted
  - Botón `"Agregar dirección"` secondary pill
- Input dirección: pill `#1a1b21`, aparece al editar, con buscador Nominatim

**Sección Historial (card `#1e1f25`, `r-16px`):**
- Label `"Mis pedidos"` uppercase muted 11px
- Lista de órdenes previas (últimas 5):
  ```
  [ #TB-00247 ] Pollo Entero × 2       $5.700
  [ Entregado ✓ ]                     20 Mar
  ```
  - Badge de estado: verde si `delivered`, ámbar si en curso, rojo si cancelado
  - Código en JetBrains Mono, fecha en muted
  - Tappable → navega a `/pedido/:id`
- Link `"Ver todos"` al final si hay más de 5

**Sección Cuenta:**
- `"Cerrar sesión"` — ghost pill con ícono logout, texto rojo suave

#### Estados
| Estado | UI |
|---|---|
| Guardando dirección | Spinner en el botón de guardar |
| Sin historial | `"Todavía no hiciste ningún pedido"` + CTA `"Ver menú"` |

---

### 2.5 Order Confirmation — `/pedido/:id`

**Dispositivo:** Mobile (390px)
**Ruta:** `/pedido/:id`
**Propósito:** Confirmación post-pedido + instrucciones de pago + tracking en tiempo real del estado.

#### Estados de la pantalla

Esta pantalla tiene **2 modos** dependiendo del estado de la orden:

**Modo A — Pending Payment** (recién creada)
**Modo B — En progreso** (confirmada → en camino → entregada)

---

#### Modo A: Pending Payment

**Badge de estado:** pill ámbar `"Esperando confirmación de pago"` + ícono reloj

**Headline:**
- `"¡Gracias!"` Inter Bold 32px blanco
- Subtexto muted: `"Tu pedido fue recibido. El local confirmará el cobro en breve."`

**Card Número de Orden (card `#1e1f25`):**
- Label `"Número de orden"` muted uppercase
- `"#TB-00247"` JetBrains Mono 20px primary verde

**Card Instrucciones de Pago (card `#1e1f25`):**

*Si Efectivo:*
- Ícono billete + `"Pago en efectivo"` SemiBold
- Texto: `"Tenés tu pedido reservado. El pago lo realizás en efectivo al momento de recibir o retirar."`
- Chip ámbar: `"El local confirmará el pedido"`

*Si Transferencia:*
- Ícono transfer + `"Transferencia a Mercado Pago"` SemiBold
- `Alias` muted → `"TWOBROTHERS.MP"` JetBrains Mono verde + botón copiar
- `Monto` muted → `"$5.700"` JetBrains Mono verde bold grande
- `Referencia` → `"#TB-00247"` JetBrains Mono muted
- Texto instrucción muted 13px: `"Realizá la transferencia y esperá la confirmación del local."`
- Chip ámbar: `"Confirmación manual por el local"`

**Timeline de Estado (card `#1e1f25`, lista vertical):**
```
● Pedido recibido         (verde ✓, completado)
◉ Confirmando pago        (ámbar pulsando, activo)
○ En preparación          (gris, pendiente)
○ En camino               (gris, pendiente)
○ Entregado               (gris, pendiente)
```
- Línea vertical ghost conectando los pasos
- Etiqueta activa en ámbar, pendientes en muted

**Resumen "The Ticket" (card `#0c0e13`, JetBrains Mono):**
```
2× Pollo Entero .......... $5.200
Envío .................... $500
Total .................... $5.700
```

**CTAs:**
- Primary pill: `"Ver estado del pedido"` (recarga/polling activo)
- Ghost pill: `"Volver al menú"`

---

#### Modo B: En Progreso / Trackeo

*El badge y el timeline actualizan automáticamente via ActionCable + polling 5s.*

**Badge de estado dinámico:**
- `confirmed` → verde `"Pedido confirmado"`
- `preparing` → ámbar `"En preparación"`
- `ready` → verde `"Listo para despachar"`
- `delivering` → ámbar pulsando `"En camino"`
- `delivered` → verde `"Entregado 🎉"`

**Timeline actualizado:**
- Mismos 5 pasos — el activo se marca en verde/ámbar según estado
- Pasos completados: verde ✓ relleno
- Paso actual: ámbar pulsando (o verde si es final)

**Mapa (solo cuando `delivering`):**
- Card `#1e1f25` con mapa incrustado (MapLibre GL / mapcn)
- Pin del repartidor en tiempo real (polling 5s)
- Pin del destino (dirección de entrega)
- Mapa con tiles OpenStreetMap, sin API key
- Altura fija ~200px en mobile

**CTAs en Modo B:**
- `delivered` → CTA `"Ver mi historial"` primary + ghost `"Volver al menú"`
- Resto → Sin CTA prominente, solo info

---

## 3. Componentes Compartidos

### Topbar (Mobile)
- Fondo glassmorphism: `#111318` @ 70% + backdrop-blur 20px
- Altura 56px + safe area top
- Contenido: `←` ícono | Título centrado | Acción derecha (badge, avatar, etc.)

### Bottom Navigation (cuando aplique)
- Fondo glassmorphism
- 3 tabs para cliente: 🏠 Menú · 🛒 Carrito · 👤 Perfil
- Tab activo: ícono y label en primary verde
- Tab inactivo: ícono muted

### Toast / Notificaciones In-App
- Fondo `#1e1f25`, pill, borde ghost primary o error
- Aparece desde arriba, duración 4s
- Tipos: `success` (verde), `error` (rojo), `info` (ámbar)

### Badge de Estado de Orden
| Estado | Color fondo | Color texto |
|---|---|---|
| `pending_payment` | `#3D2E10` | `#F4A261` |
| `confirmed` | `#1A3D2B` | `#40c97f` |
| `preparing` | `#3D2E10` | `#F4A261` |
| `ready` | `#1A3D2B` | `#40c97f` |
| `delivering` | `#3D2E10` | `#F4A261` |
| `delivered` | `#1A3D2B` | `#40c97f` |
| `cancelled` | `#3B1219` | `#ffb4ab` |

### "The Ticket" Component
- Fondo `#0c0e13`, `r-16px`
- Todo el texto en JetBrains Mono
- Líneas de ítem: texto muted izquierda, precio verde derecha
- Separador: línea ghost `#3d4a40` @ 15%
- Total: Inter SemiBold blanco izquierda, JetBrains Mono verde bold derecha, mayor tamaño

---

## 4. Notas para Stitch

### Prompts Clave
- Siempre incluir: `"dark theme, background #111318, no borders or dividers, depth through color shifts only"`
- Siempre mencionar: `"Inter font, JetBrains Mono for prices and codes, Lucide icons 2px stroke"`
- Siempre mencionar: `"pill buttons 999px radius, cards 16px radius"`
- Para CTAs: `"primary CTA: linear gradient #61e698 to #40c97f at 135deg, text color #00391d"`

### Pantallas a Generar
| Pantalla | Dispositivo | Ruta | Estado |
|---|---|---|---|
| Login | Mobile | `/login` | ✅ Generada |
| Cart | Mobile | `/carrito` | ✅ Generada |
| Checkout (bottom sheet) | Mobile | — | 🔲 Pendiente |
| Profile | Mobile | `/perfil` | 🔲 Pendiente |
| Order Confirm (Modo A) | Mobile | `/pedido/:id` | 🔲 Pendiente |
| Order Confirm (Modo B — delivering) | Mobile | `/pedido/:id` | 🔲 Pendiente |

### IDs de Pantallas Generadas en Stitch
| Pantalla | Screen ID |
|---|---|
| Login Screen | `projects/12021064967750037147/screens/53b1c5fabf81418180d5653f332def02` |
| Cart & Checkout | `projects/12021064967750037147/screens/ca06a9f1f1a548899b13884d960a01aa` |
