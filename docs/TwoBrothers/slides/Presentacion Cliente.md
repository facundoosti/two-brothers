---
proyecto: Two Brothers
tipo: Presentación Cliente
fecha: '2026-03-19'
estado: Lista
tags:
  - presentacion
  - cliente
  - mvp
  - two-brothers
---

# Two Brothers — Presentación Cliente

> Presentación de propuesta MVP para el cliente. 11 slides. Diseño en `two_brothers_presentacion.pen`.

---

## Slide 01 — Cover

![[slides/KQzWZ.png]]

**Badge superior**
> 🔥 Propuesta de solución · MVP 2026

**Título principal**
> # Two Brothers

**Subtítulo**
> Gestión digital de tu negocio

**Panel derecho**
> 🏪 Un sistema para todo tu negocio
> Cliente · Admin · Repartidor

---

## Slide 02 — El Problema

![[slides/URrOJ.png]]

**Badge**
> ⚠️ El problema actual

**Título**
> ## ¿Cómo manejás el negocio hoy?

**Pain points**
- ❌ Órdenes tomadas en papel o de forma verbal
- ❌ Sin visibilidad del estado de cada pedido
- ❌ Repartidores sin coordinación centralizada
- ❌ Sin historial de ventas ni reportes

**Panel derecho**
> 📄 Gestión manual = errores y caos
> Cada error cuesta tiempo y clientes

---

## Slide 03 — La Solución

![[slides/vlvSa.png]]

**Badge**
> ✅ La solución

**Statement principal**
> # Una sola app.
> # Tres roles.
> # Control total.

**Subtítulo**
> Two Brothers digitaliza todo: del pedido online a la entrega — sin papel, sin caos.

---

## Slide 04 — Los 3 Roles

![[slides/AnRRg.png]]

**Título de sección**
> ¿Quién usa la app?
> ## Tres roles, una sola plataforma

---

**🛒 Cliente** — *El que hace el pedido*
- → Menú online con categorías
- → Carrito y pago (MP/efectivo)
- → Seguimiento del pedido en tiempo real
- → Historial de órdenes anteriores

**⊞ Admin** *(Principal)* — *El dueño / operador*
- → Dashboard con métricas del día
- → Gestión completa de órdenes
- → Asignación de repartidores
- → Menú, reportes y configuración

**🚲 Repartidor** — *El que entrega*
- → Lista de repartos asignados
- → Detalle del pedido a entregar
- → GPS activo durante el reparto
- → Actualizar estado en tiempo real

---

## Slide 05 — Flujo Completo de una Orden

![[slides/vPgWf.png]]

**Título de sección**
> Del pedido a la entrega
> ## Flujo completo de una orden

| Paso | Nombre | Descripción |
|---|---|---|
| 🛒 1 | **Pedido** | El cliente arma su carrito y confirma el pedido online |
| 💳 2 | **Pago** | Admin confirma el cobro (efectivo o transferencia MP) |
| 👨‍🍳 3 | **Cocina** | La orden pasa a preparación y queda lista para despacho |
| 🚲 4 | **Despacho** | Admin asigna repartidor. El cliente ve el GPS en tiempo real |
| ✅ 5 | **Entrega** | Pedido entregado. Queda en el historial del cliente |

---

## Slide 06 — Panel Cliente

![[slides/87ms4.png]]

**Badge**
> 👤 Vista del Cliente

**Título**
> ## Todo lo que ve el cliente

**Features**
- 🍽️ Menú con categorías e ítems y precios
- 🛍️ Carrito: modalidad, dirección y pago
- 📍 Tracking en tiempo real del pedido y GPS
- 🕓 Historial completo de órdenes

**Panel derecho**
> 📱 App mobile-first
> Funciona en cualquier celular, sin necesidad de instalar nada

---

## Slide 07 — Panel Admin

![[slides/XS3RW.png]]

**Badge**
> 🛡️ Panel Admin

**Título**
> ## Control total del negocio

**Features**
- 📊 Dashboard: métricas, ventas y stock del día
- 📋 Gestión de órdenes con cambio de estado
- 👥 Repartidores: asignación y seguimiento GPS
- 📖 Gestión del menú (ABM de ítems y categorías)
- 📈 Reportes de ventas: diario, semanal, mensual

**KPIs destacados**

| Número | Contexto |
|---|---|
| **100** | unidades/día — stock configurable |
| **4** | máximo de unidades por orden |
| **Jue–Dom** | horario 20:00–00:00 hs (configurable) |

---

## Slide 08 — Panel Repartidor

![[slides/vp6wV.png]]

**Badge**
> 🚲 Vista del Repartidor

**Título**
> ## El panel del repartidor

**Features**
- ✅ Lista de repartos asignados pendientes
- 🗺️ Reparto actual con dirección y datos
- 📍 GPS automático mientras está en camino
- ✔️ Confirma entrega con un solo toque

**Panel derecho**
> 📍 GPS en tiempo real
> El cliente y el admin ven la posición del repartidor actualizada cada 5 segundos

---

## Slide 09 — Reglas de Negocio

![[slides/YzvPm.png]]

**Título de sección**
> Lo que rige el negocio
> ## Reglas de negocio clave

**📦 Stock diario**
> 100 unidades por día (configurable). Se descuenta al confirmar. Se devuelve si se cancela. Máx. 4 por orden.

**🕐 Horario de atención**
> Jueves a domingo, 20:00–00:00 hs. Fuera de horario el menú se muestra, pero los pedidos están bloqueados.

**💵 Pagos**
> Efectivo al momento de la entrega o transferencia a alias CVU de Mercado Pago. Confirmación manual por el admin.

**🚫 Cancelaciones**
> Solo el admin puede cancelar. Permitido hasta estado 'Confirmada'. No se puede cancelar si ya está en preparación o entregada.

---

## Slide 10 — Stack Tecnológico

![[slides/4oPEg.png]]

**Título de sección**
> Tecnología de primer nivel
> ## Stack moderno y confiable

| Tecnología | Rol | Descripción |
|---|---|---|
| ⚡ **React + TypeScript** | Frontend | Moderno, rápido y responsive |
| 🖥️ **Ruby on Rails** | Backend | API robusta y segura |
| 🗄️ **PostgreSQL** | Base de datos | Confiable y escalable |
| 🔔 **WebSockets** | Tiempo real | Notificaciones de cada cambio de estado |
| 💳 **Mercado Pago** | Pagos | Cobros online integrados, sin salir de la app |

---

## Slide 11 — Cierre

![[slides/NrSLp.png]]

**Badge**
> 🚀 Siguiente paso

**Headline**
> # ¿Arrancamos?

**Subtítulo**
> Two Brothers está listo para digitalizar tu negocio de principio a fin — sin papel, sin errores, con datos.

**CTA**
> 💬 **Hablemos**

---

## Notas para la presentación

- **Duración estimada:** 15–20 minutos
- **Audiencia:** Dueño del local (no técnico)
- **Foco del mensaje:** valor de negocio, no tecnología
- **Énfasis en slides:** 2 (problema), 5 (flujo), 7 (admin con KPIs)
- **Abrir debate en:** slide 9 (reglas) — validar stock, horario y pagos con el cliente
