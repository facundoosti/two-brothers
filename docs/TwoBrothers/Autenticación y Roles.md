# Autenticación y Roles

## Flujo de autenticación

Todos los usuarios deben estar autenticados vía **Google OAuth 2.0** para acceder a cualquier ruta de la app.

```
Usuario abre la app
  → no autenticado → redirige a /login
  → autenticado, sin rol asignado → queda en /login con mensaje "pendiente de activación"
  → autenticado, con rol → redirige al home según su rol
```

### Home por rol

| Rol | Ruta de inicio |
|---|---|
| `admin` | `/admin` |
| `delivery` | `/delivery` |
| `customer` | `/` (menú) |

---

## Roles del sistema

| Rol | Quién lo asigna | Descripción |
|---|---|---|
| `admin` | Solo desde backend | Acceso completo al panel admin |
| `delivery` | Admin desde `/admin/usuarios` | Repartidores activos |
| `customer` | Asignado automáticamente al registrarse | Clientes que hacen pedidos |

### Estado de usuario

- **`active`** — puede operar normalmente según su rol
- **`pending`** — se autenticó con Google pero el admin aún no activó/asignó su rol

---

## Implementación frontend

### Auth store (`src/store/authStore.ts`)
Zustand con `persist` en `localStorage`. Guarda el usuario autenticado (`User | null`).

```ts
interface AuthState {
  user: User | null
  setUser: (user: User) => void
  clearUser: () => void
}
```

### ProtectedRoute (`src/features/auth/ProtectedRoute.tsx`)
Wrapper component que verifica autenticación y rol.
- Sin usuario → redirige a `/login`
- Rol no permitido → redirige al home del rol del usuario

Usado en cada layout:
- `AdminLayout` → `allowedRoles={['admin']}`
- `CustomerLayout` → `allowedRoles={['customer', 'admin']}`
- `DeliveryLayout` → `allowedRoles={['delivery']}`

### Tipo User (`src/types/users.ts`)
```ts
export type UserRole = 'admin' | 'delivery' | 'customer'
export type UserStatus = 'active' | 'pending'
export interface User { id, name, email, avatar?, role, status, createdAt }
```

---

## Panel de Usuarios (`/admin/usuarios`)

Nueva sección del panel admin para gestión de usuarios.

### Funcionalidades
- Ver todos los usuarios registrados (tabla)
- Filtrar por rol o buscar por nombre/email
- Cambiar rol entre `customer` y `delivery` (el admin no se puede modificar)
- Activar usuarios en estado `pending`

### Reglas
- Solo el admin puede cambiar roles
- El rol `admin` solo se asigna desde el backend
- Al promover a `delivery`, el usuario se activa automáticamente
- Los usuarios `pending` no pueden acceder a ninguna ruta

---

## Ruta nueva

| Ruta | Componente |
|---|---|
| `/admin/usuarios` | `AdminUsersPage` |

Accesible desde el sidebar admin bajo la sección **Configuración**.
