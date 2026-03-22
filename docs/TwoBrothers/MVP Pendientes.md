# Two Brothers — Tareas pendientes MVP

Última actualización: 2026-03-21

---

## Estado general del proyecto

El flujo completo cliente → admin → repartidor está operativo. Todas las páginas usan datos reales de la API. Lo que sigue son las features que faltan para cerrar el MVP.

---

## 🟡 Importante — afecta UX pero no bloquea

### 1. ReportsPage — datos reales
**Dónde:** `api/` + `app/src/features/admin/ReportsPage.tsx`  
**Qué:** La página de reportes está completamente hardcodeada. Falta:
- **Backend:** `GET /api/v1/reports` con datos agregados: ventas totales del período, órdenes por estado, top ítems vendidos, ventas por día de la semana.
- **Frontend:** Conectar `ReportsPage` a ese endpoint reemplazando los arrays estáticos.
- **Filtro por rango de fechas:** parámetros `?from=&to=` en el endpoint.

### 2. Alias MP dinámico en OrderPage
**Dónde:** `app/src/features/customer/OrderPage.tsx` línea 88  
**Qué:** El alias de Mercado Pago está hardcodeado como `"twobrothers.mp"`. Debe leerlo del setting `mp_alias`.  
**Opción más simple:** Hacer `GET /api/v1/settings` público para clientes (solo lectura de `mp_alias`) o incluirlo en la respuesta de categorías.

---

## 🟢 Nice to have — post-MVP

### 3. Paginación en UsersPage
**Dónde:** `app/src/features/admin/UsersPage.tsx`  
**Qué:** Carga todos los usuarios sin paginación. Agregar controles Pagy si crece el negocio.

### 4. Notificaciones push / sonido en AdminDashboard
**Dónde:** `app/src/features/admin/DashboardPage.tsx`  
**Qué:** Cuando llega una orden nueva (ActionCable conectado), emitir un sonido o notificación del browser para alertar al admin sin que esté mirando la pantalla.

### 5. Foto de perfil del usuario (avatar)
**Dónde:** `AdminSidebar`, `UsersPage`  
**Qué:** `User.avatar_url` existe en el tipo pero se muestran iniciales. Si Google OAuth devuelve foto, mostrarla.

---

## ✅ Completado

- [x] Flujo completo cliente: menú → carrito → orden → tracking en tiempo real
- [x] Admin: dashboard, órdenes, detalle de orden, asignación de repartidor
- [x] Admin: gestión de menú (CRUD categorías e ítems)
- [x] Admin: gestión de usuarios (roles, activación)
- [x] Admin: configuración del local (horario, stock, alias MP, nombre y dirección)
- [x] Admin: orden desde mostrador (modal en Órdenes → nace directamente en confirmed)
- [x] Repartidor: lista de repartos, reparto actual con GPS watchPosition
- [x] ActionCable: notificaciones en tiempo real de cambio de estado de órdenes
- [x] Geocoder: dirección → lat/lng en el backend (Nominatim, sin API key)
- [x] Buscador de direcciones en carrito (Nominatim directo, biased a Dolores)
- [x] ResetDailyStockJob con Solid Queue (midnight)
- [x] Pundit: autorización por rol en todos los endpoints
- [x] Tracking en mapa para admin y cliente (polling 5s)
