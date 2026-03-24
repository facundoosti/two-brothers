---
proyecto: Two Brothers
tipo: Reglas de Negocio
estado: Confirmado
fecha_creacion: '2026-03-16'
fecha_actualizacion: '2026-03-22'
tags:
  - reglas
  - negocio
  - two-brothers
---

# Reglas de Negocio — Two Brothers

> Reglas que gobiernan el comportamiento del sistema más allá del flujo técnico. Deben reflejarse en validaciones del modelo, permisos de controlador y lógica de UI.

---

## 1. Stock de Producto por Ítem

### 1.1 Configuración
- Cada `MenuItem` tiene un campo `daily_stock` (entero, nullable) que define la **cuota diaria** de ese ítem
- Si `daily_stock` es `null` o `0`, el ítem está **bloqueado** — no se puede ordenar
- El admin configura el `daily_stock` de cada ítem desde el panel de menú
- El stock **se resetea automáticamente cada día a las 00:00** via `ResetDailyStockJob` (Solid Queue)
- Al resetear, se crea un nuevo registro `DailyStock` por ítem tomando el valor de `MenuItem#daily_stock` como `total`, con `used = 0`

### 1.2 Descuento de Stock
- El stock se trackea por `DailyStock` (un registro por `menu_item_id` + `date`)
- La cantidad pedida de cada ítem descuenta de su propio `DailyStock`
- El stock se descuenta en el momento en que se **confirma la orden** (status: `confirmed`)
- Si la orden es cancelada antes de ser confirmada, **no se descuenta stock**
- Si la orden es cancelada después de `confirmed`, el stock **se devuelve** por ítem

### 1.3 Control de Disponibilidad
- Si el `DailyStock` de un ítem llega a `used == total`, ese ítem queda sin stock
- El portal del cliente muestra el ítem deshabilitado cuando no hay stock
- El admin puede ver en el dashboard el stock por ítem del día
- **El cliente puede pedir hasta 10 unidades del mismo ítem por orden**
- Validación al crear la orden y al confirmar: `used + cantidad_solicitada <= total` por ítem
- Si el stock disponible de un ítem es menor a la cantidad pedida, la orden se bloquea con mensaje por ítem

---

## 2. Cancelación de Órdenes

### 2.1 ¿Quién puede cancelar?
- **Solo el admin** puede cancelar una orden
- El cliente **no puede cancelar** su propia orden desde la app
- El repartidor **no puede cancelar**

### 2.2 ¿Hasta cuándo se puede cancelar?
- Se puede cancelar desde `pending_payment` y `confirmed`
- **No se puede cancelar** una orden en estado `preparing`, `ready`, `delivering` o `delivered`

### 2.3 Efecto de la cancelación
| Estado al cancelar | Devuelve stock |
|---|---|
| `pending_payment` | No (el stock no fue descontado aún) |
| `confirmed` | Sí (+1 al stock disponible del día) |

### 2.4 Estado de pago al cancelar
- El campo `paid` en la orden **persiste independientemente** del estado de la orden.
- Si se cancela una orden que nunca fue pagada (`pending_payment → cancelled`): `paid = false` → se muestra **"Sin pagar"**
- Si se cancela una orden que ya fue confirmada (`confirmed → cancelled`): `paid = true` → se muestra **"Pagado"**
- Esto evita que el panel de admin muestre "Pagado" incorrectamente en órdenes canceladas sin cobro.

### 2.5 Comunicación al cliente
- Al cancelar, el sistema notifica al cliente via ActionCable con el mensaje:
  > *"Tu pedido fue cancelado. Comunicate con nosotros si tenés dudas."*

---

## 3. Gestión de Órdenes desde el Mostrador

### 3.1 El operador puede crear órdenes para un cliente
- El operador busca al cliente por nombre o email en el panel
- Selecciona los ítems del menú y la modalidad (delivery o pickup)
- Confirma el pago de inmediato (se asume cobro presencial)
- La orden se crea directamente en `confirmed`, saltando `pending_payment`

### 3.2 Dirección de entrega
- El cliente (`customer`) tiene una **dirección de entrega guardada** en su perfil
- Al crear una orden (desde el portal o desde el mostrador), la dirección del perfil se **sugiere por defecto**
- Tanto el cliente como el operador pueden **modificar la dirección** para esa orden específica sin alterar la del perfil

---

## 4. Configuración del Local (Admin)

### 4.1 Ajustes configurables por el admin
| Ajuste | Descripción |
|---|---|
| `store_name` | Nombre del local |
| `mp_alias` | Alias CVU de Mercado Pago para recibir transferencias |
| `store_address` | Dirección del local (para retiros) |
| `store_name` | Nombre del local (Two Brothers) |
| `open_days` | Días de atención (default: jueves, viernes, sábado, domingo) |
| `opening_time` | Hora de apertura (default: 20:00) |
| `closing_time` | Hora de cierre (default: 00:00) |

> Estos ajustes se gestionan desde una sección **"Configuración"** en el panel de admin. Se almacenan en un modelo `Setting` tipo clave-valor.

---

## 5. Horario de Atención

### 5.1 Configuración
- El local atiende de **Jueves a Domingo, de 20:00 a 00:00 (medianoche)**

> ✅ Horario confirmado: **20:00 a 00:00 del mismo día**.
> ✅ Las órdenes en curso al momento del cierre **siguen su flujo normal** sin interrupción.

- El horario es configurable por el admin desde el panel (`Setting: opening_hours`)
- Los días de atención son configurables (`Setting: open_days`)

### 5.2 Comportamiento fuera de horario
- El portal del cliente muestra el menú pero **bloquea la creación de órdenes**
- Se muestra un mensaje con el próximo horario de apertura:
  > *"Estamos cerrados. Volvemos el [día] a las 20:00 hs."*
- El panel de admin y el panel de repartidor **no tienen restricción de horario**

### 5.3 Validación
- La validación de horario se aplica en el backend al crear la orden (`POST /api/orders`)
- El frontend también oculta / deshabilita el botón de confirmar fuera de horario

---

## 6. Flujo de Estados — Responsables por Rol ✅

> Actualizado 2026-03-22. Los flujos difieren según modalidad.

### 6.1 Flujo Delivery

```
pending_payment → confirmed → preparing → ready → delivering → delivered
                                                        ↑
                                   repartidor marca delivered desde aquí
```

| Transición | Responsable | Mecanismo |
|---|---|---|
| `pending_payment → confirmed` | **Admin** | Confirmar cobro manual en panel |
| `confirmed → preparing` | **Admin** | Botón "Iniciar preparación" |
| `preparing → ready` | **Admin** | Botón "Marcar lista" |
| `ready → delivering` | **Admin** | Botón "Marcar en camino" |
| `delivering → delivered` | **Repartidor** | Botón "Marcar entregado" en su panel |
| → `cancelled` | **Solo admin** | Hasta `confirmed` inclusive |

### 6.2 Flujo Retiro en Local (Pickup)

**Caso A — Orden online (nace en `pending_payment`):**

```
pending_payment ──[admin: confirmar pago]──► delivered
```

- Al confirmar el pago de una orden de retiro, la orden pasa **directamente a `delivered`**.
- El cliente retira el pedido en el momento — no hay estados intermedios.
- No se asigna repartidor. No existe estado `delivering` para pickup.

**Caso B — Orden de mostrador (nace en `confirmed`):**

```
confirmed → preparing → ready ──[admin: marcar entregada]──► delivered
```

- Las órdenes de mostrador se crean directamente en `confirmed` (cobro presencial asumido).
- El admin avanza la preparación y al llegar a `ready` puede marcarla como entregada directamente.
- No pasa por `delivering`.

| Transición | Responsable | Mecanismo |
|---|---|---|
| `pending_payment → delivered` | **Admin** | Confirmar pago (flujo pickup directo) |
| `confirmed → preparing` | **Admin** | Botón "Iniciar preparación" |
| `preparing → ready` | **Admin** | Botón "Marcar lista" |
| `ready → delivered` | **Admin** | Botón "Marcar como entregada" |
| → `cancelled` | **Solo admin** | Hasta `confirmed` inclusive |

### 6.3 Reglas generales del flujo
- **El repartidor NO puede cancelar ni avanzar estados de la orden.** Solo puede actualizar su `DeliveryAssignment` a `in_transit` o `delivered`, lo que dispara internamente `order.mark_delivered!`.
- El evento AASM `start_delivering` tiene guard `:delivery?` — no puede ejecutarse en órdenes pickup.
- Los eventos `complete_pickup` y `complete_ready_pickup` tienen guard `:pickup?` — no pueden ejecutarse en órdenes delivery.
- Cuando el repartidor marca `in_transit` su assignment, el backend intenta avanzar la orden a `delivering` solo si `may_start_delivering?` es verdadero (guard natural del estado).

---

## 7. Pagos — Definición Final ✅

> Confirmado 2026-03-21. Sin integración de pagos online.

- **Medios aceptados:** efectivo en mano o transferencia bancaria al alias CVU de Mercado Pago.
- **Sin Checkout Pro, Checkout API ni webhooks de Mercado Pago.**
- El admin confirma el pago **manualmente** desde el panel una vez verificado el cobro.
- El alias CVU es configurable en `Configuración → mp_alias`.
- El campo `paid` (boolean) en la orden se setea a `true` en el momento de confirmar el pago y **no cambia** aunque la orden sea cancelada posteriormente. Es la fuente de verdad para mostrar el estado de pago en el panel.

---

## 8. Cálculo del Total

- El campo `total` de la orden representa el **subtotal de ítems** (sin delivery fee).
- Se calcula en el backend al crear la orden: `sum(quantity × unit_price)` sobre los `order_items`.
- El frontend **no envía** el campo `total` — el backend lo calcula para evitar manipulación.
- El `delivery_fee` se almacena por separado y se toma del setting `delivery_fee` si está habilitado.
- El total a pagar que ve el admin y el cliente es: `total + delivery_fee`.

---

## Log de Decisiones

| Fecha | Decisión | Estado |
|---|---|---|
| 2026-03-23 | Stock por ítem: cada MenuItem tiene su propio daily_stock y DailyStock record por día | ✅ |
| 2026-03-23 | Máximo 10 unidades del mismo ítem por orden | ✅ |
| 2026-03-23 | daily_stock null o 0 bloquea el ítem (no se puede ordenar) | ✅ |
| 2026-03-16 | Horario: 20:00–00:00 del mismo día, Jueves a Domingo | ✅ |
| 2026-03-16 | Órdenes en curso al cierre siguen flujo normal sin interrupción | ✅ |
| 2026-03-16 | Solo admin puede cancelar órdenes | ✅ |
| 2026-03-16 | Cancelación permitida hasta `confirmed` inclusive | ✅ |
| 2026-03-16 | Stock se descuenta al confirmar y se devuelve al cancelar | ✅ |
| 2026-03-16 | Dirección del perfil se sugiere por defecto, editable por orden | ✅ |
| 2026-03-16 | Alias CVU configurable por el admin desde el panel | ✅ |
| 2026-03-16 | Orden desde mostrador nace directamente en `confirmed` | ✅ |
| 2026-03-21 | Flujo de estados confirmado: admin maneja preparing/ready/delivering, repartidor marca delivered | ✅ |
| 2026-03-21 | Sin integración de pagos online — solo efectivo y transferencia, confirmación manual admin | ✅ |
| 2026-03-22 | Campo `paid` independiente del status para trackear pago real (evita bug de canceladas que aparecen como pagadas) | ✅ |
| 2026-03-22 | Total calculado en backend desde order_items, frontend no lo envía | ✅ |
| 2026-03-22 | Pickup online: confirmar pago → delivered directo (sin estados intermedios) | ✅ |
| 2026-03-22 | Pickup mostrador: confirmed → preparing → ready → delivered (sin delivering) | ✅ |
| 2026-03-22 | Guards AASM en start_delivering (solo delivery) y complete_pickup/complete_ready_pickup (solo pickup) | ✅ |
| 2026-03-22 | Repartidor marca in_transit: backend avanza orden a delivering solo si may_start_delivering? (guard natural) | ✅ |
