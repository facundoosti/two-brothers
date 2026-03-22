---
proyecto: Two Brothers
tipo: Flujo
estado: En definición
fecha_creacion: '2026-03-16'
tags:
  - flujo
  - orden
  - happy-path
  - two-brothers
---

# Happy Path — Ciclo Completo de una Orden

> Describe el flujo ideal (sin errores, sin cancelaciones) de una orden con modalidad **delivery**, desde que el cliente arma el carrito hasta que recibe el pedido en su domicilio.
> El flujo de **retiro en local** se detalla al final como variante.

---

## Actores involucrados

| Actor | Rol en el flujo |
|---|---|
| **Cliente** | Inicia la orden, elige medio de pago, hace seguimiento |
| **Sistema (Rails API)** | Orquesta estados y dispara notificaciones |
| **Admin / Operador** | Confirma el pago, gestiona la orden y asigna repartidor |
| **Cocina** | Cambia el estado a "en preparación" y "listo" |
| **Repartidor** | Acepta, sale y entrega el pedido |

> ✅ No hay integración con APIs externas de pago en el MVP. Sin webhooks de Mercado Pago.

---

## Diagrama del Flujo

```
CLIENTE                  SISTEMA (Rails)            ADMIN/COCINA          REPARTIDOR
   │                           │                         │                     │
   │  1. Arma carrito          │                         │                     │
   │  2. Elige delivery        │                         │                     │
   │  3. Ingresa dirección     │                         │                     │
   │  4. Elige medio de pago   │                         │                     │
   │  5. Confirma pedido ─────►│                         │                     │
   │                           │  6. Crea Order          │                     │
   │                           │     pending_payment     │                     │
   │                           │  7. Notif: nueva orden ►│                     │
   │◄── 8. Pantalla de espera  │                         │                     │
   │    + instrucciones pago   │                         │  9. Ve orden        │
   │                           │                         │     pending_payment │
   │                           │                         │  10. Confirma pago  │
   │                           │◄────────────────────────│  (botón en panel)   │
   │                           │  11. Order: confirmed   │                     │
   │◄── 12. Notif: confirmada  │                         │                     │
   │                           │                         │  13. Pasa a cocina  │
   │                           │                         │  14. preparing ────►│
   │◄── 15. Notif: preparando  │◄────────────────────────│                     │
   │                           │                         │  16. ready          │
   │◄── 17. Notif: listo       │◄────────────────────────│                     │
   │                           │                         │  18. Asigna         │
   │                           │                         │      repartidor ───►│
   │                           │                         │                     │  19. Ve reparto
   │                           │                         │                     │  20. Acepta y sale
   │                           │  delivering ◄───────────│◄────────────────────│
   │◄── 21. Notif: en camino   │                         │                     │
   │  22. Ve mapa (polling 5s) │◄───────────────────────────────────────────►│
   │                           │                         │                     │  23. Entrega
   │                           │  delivered ◄────────────│◄────────────────────│
   │◄── 24. Notif: entregado   │                         │                     │
   │  25. Ve historial         │                         │                     │
```

---

## Detalle de Pasos

### Fase 1 — Creación del Pedido (Cliente)

| # | Paso | Actor | Estado |
|---|---|---|---|
| 1 | Navega el menú y agrega ítems al carrito | Cliente | — |
| 2 | Selecciona modalidad: **delivery** | Cliente | — |
| 3 | Ingresa dirección de entrega y datos de contacto | Cliente | — |
| 4 | Selecciona medio de pago: **efectivo** o **transferencia a alias MP** | Cliente | — |
| 5 | Confirma el pedido | Cliente | — |
| 6 | Rails crea la `Order` con `status: pending_payment` | Sistema | `pending_payment` |
| 7 | Sistema notifica al admin/operador: nueva orden ingresada | Sistema | `pending_payment` |
| 8 | Cliente ve pantalla de espera con instrucciones según el medio de pago elegido | Sistema | `pending_payment` |

#### Instrucciones por medio de pago

**Efectivo**
- Pantalla muestra: *"Tenés tu pedido reservado. El pago lo realizás en efectivo al momento de recibir / retirar."*
- Admin confirma el cobro cuando el cliente paga presencialmente o en la entrega

**Transferencia a alias MP**
- Pantalla muestra el **alias CVU** del local (configurado por el admin en ajustes)
- Muestra monto total y número de orden como referencia de la transferencia
- Mensaje: *"Realizá la transferencia y esperá la confirmación del local."*
- Admin verifica el ingreso en su app de MP y confirma manualmente desde el panel

---

### Fase 2 — Confirmación del Pago (Admin/Operador)

| # | Paso | Actor | Estado |
|---|---|---|---|
| 9 | Admin ve la orden en `pending_payment` en su panel con el medio de pago indicado | Admin | `pending_payment` |
| 10 | Admin verifica el pago (en persona o revisando su cuenta de MP) | Admin | `pending_payment` |
| 11 | Admin presiona **"Confirmar pago"** en el panel → Rails actualiza a `confirmed` | Admin | `confirmed` |
| 12 | Sistema notifica al cliente via ActionCable: *"Tu pedido fue confirmado"* | Sistema | `confirmed` |

> 💡 El botón "Confirmar pago" es el mismo para efectivo y transferencia. El admin es responsable de verificar antes de confirmar. Sin automatización en el MVP.

---

### Fase 3 — Preparación en Cocina

| # | Paso | Actor | Estado |
|---|---|---|---|
| 13 | Admin/Cocina cambia el estado a `preparing` | Admin/Cocina | `preparing` |
| 14 | Sistema notifica al cliente: *"Tu pedido está en preparación"* | Sistema | `preparing` |
| 15 | Cocina cambia el estado a `ready` | Admin/Cocina | `ready` |
| 16 | Sistema notifica al cliente: *"Tu pedido está listo para despachar"* | Sistema | `ready` |

---

### Fase 4 — Asignación y Despacho

| # | Paso | Actor | Estado |
|---|---|---|---|
| 17 | Admin asigna el pedido a un repartidor disponible | Admin | `ready` |
| 18 | Repartidor recibe notificación: nuevo reparto asignado | Sistema | `ready` |
| 19 | Repartidor acepta el reparto y marca salida | Repartidor | — |
| 20 | Rails actualiza `Order` a `delivering` y `DeliveryAssignment` a `in_transit` | Sistema | `delivering` |
| 21 | Sistema notifica al cliente: *"Tu pedido está en camino"* | Sistema | `delivering` |

---

### Fase 5 — Trackeo en Tiempo Real

| # | Paso | Actor | Mecanismo |
|---|---|---|---|
| 22a | Browser del repartidor detecta movimiento con `watchPosition()` | Repartidor | Geolocation API |
| 22b | React hace `POST /api/delivery_locations` con lat/lng en cada movimiento | React → Rails | HTTP |
| 22c | Cliente/Admin consultan `GET /api/delivery_locations/:id/latest` cada 5s | TanStack Query | Polling |
| 22d | Mapa se actualiza con la nueva posición del repartidor | React | Re-render |

> 🟡 Librería de mapas: **Leaflet** (pendiente confirmación final)

---

### Fase 6 — Entrega

| # | Paso | Actor | Estado |
|---|---|---|---|
| 23 | Repartidor confirma la entrega en su panel | Repartidor | — |
| 24 | Rails actualiza `Order` a `delivered` y registra `delivered_at` | Sistema | `delivered` |
| 25 | Sistema notifica al cliente: *"¡Tu pedido fue entregado!"* | Sistema | `delivered` |
| 26 | Pedido aparece en el historial del cliente como completado | — | `delivered` |

---

## Estados de una Orden

```
                    ┌── admin confirma cobro en efectivo ──────────────────┐
                    │                                                      ▼
pending_payment ────┤                                                  confirmed ──► preparing ──► ready ──► delivering ──► delivered
                    │                                                      │
                    └── admin confirma transferencia (botón en panel) ────┘

Desde pending_payment, confirmed o preparing → cancelled (*)
Una vez en ready o posterior → no cancelable en el MVP
```

---

## Variante — Retiro en Local (Pickup)

Flujo idéntico hasta la **Fase 3**. Diferencias:

| Punto | Diferencia |
|---|---|
| Fase 4 | No se asigna repartidor |
| Fase 5 | No hay trackeo GPS |
| Confirmación de entrega | Admin marca `delivered` cuando el cliente retira en el local |
| Notificación en paso 16 | *"Tu pedido está listo para retirar"* en lugar de *"listo para despachar"* |

---

## Endpoints API de este Flujo

> Borrador — se detallará en el contrato de API

| Método | Ruta | Actor | Descripción |
|---|---|---|---|
| `POST` | `/api/orders` | Cliente | Crea la orden con `pending_payment` |
| `GET` | `/api/orders/:id` | Cliente | Estado actual de la orden (TanStack Query polling) |
| `PATCH` | `/api/orders/:id/confirm_payment` | Admin | Confirma el pago → `confirmed` |
| `PATCH` | `/api/orders/:id/status` | Admin/Cocina | Cambia estado: `preparing`, `ready`, `cancelled` |
| `POST` | `/api/delivery_assignments` | Admin | Asigna repartidor a una orden |
| `PATCH` | `/api/delivery_assignments/:id/status` | Repartidor | Actualiza estado: `in_transit`, `delivered` |
| `POST` | `/api/delivery_locations` | Repartidor | Envía coordenadas GPS |
| `GET` | `/api/delivery_locations/:assignment_id/latest` | Cliente/Admin | Última posición del repartidor |

---

## Decisiones de este Flujo

| Fecha | Decisión | Estado |
|---|---|---|
| 2026-03-16 | MVP sin integración de tarjeta de crédito/débito | ✅ |
| 2026-03-16 | Medios de pago: efectivo y transferencia a alias MP | ✅ |
| 2026-03-16 | Sin webhooks de MP — flujo 100% manual | ✅ |
| 2026-03-16 | Confirmación de pago: botón "Confirmar pago" en panel del admin | ✅ |
| 2026-03-16 | Librería de mapas: Leaflet | 🟡 |

---

## Pendientes de este Flujo

- 🔲 ¿El cliente puede cancelar su orden desde la app? ¿Hasta qué estado?
- 🔲 Flujo de orden desde mostrador (sin portal de cliente)
- 🔲 ¿Qué ve el cliente si el admin rechaza / cancela su orden?
- 🔲 ¿El alias CVU se configura desde el panel de admin o está hardcodeado en el MVP?
