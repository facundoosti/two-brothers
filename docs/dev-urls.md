# URLs de desarrollo

## Cómo funciona en local

El dominio de producción es `two-brothers.shop`. En desarrollo se usa **`lvh.me`** como reemplazo: es un dominio público que resuelve a `127.0.0.1`, lo que permite subdominios reales sin configuración extra.

```
tastychicken.two-brothers.shop  ←→  tastychicken.lvh.me (dev)
admin.two-brothers.shop         ←→  admin.lvh.me        (dev)
two-brothers.shop               ←→  lvh.me              (dev)
```

---

## URLs de la API (Rails · puerto 3000)

| Contexto | URL |
|---|---|
| Tenant "tastychicken" | `http://tastychicken.lvh.me:3000` |
| Panel superadmin | `http://admin.lvh.me:3000` |
| Sin tenant (landing / público) | `http://lvh.me:3000` |
| Fallback local (sin internet) | `http://localhost:3000` |

## URLs del Frontend (Vite · puerto 5173)

| Contexto | URL |
|---|---|
| Tenant "tastychicken" | `http://tastychicken.lvh.me:5173` |
| Sin tenant | `http://lvh.me:5173` |
| Fallback local (sin internet) | `http://localhost:5173` |

> El frontend detecta el tenant desde `window.location.hostname` y apunta la API al mismo host en el puerto 3000 automáticamente. No hay que configurar nada extra.

---

## Arrancar en desarrollo

```bash
# Terminal 1 — API
cd api
bin/rails server -p 3000

# Terminal 2 — Frontend
cd app
npm run dev -- --host
```

Luego abrir: `http://tastychicken.lvh.me:5173`

---

## Fallback sin internet (DEFAULT_TENANT)

Si no hay conexión a internet `lvh.me` no resuelve. Usar la variable de entorno `DEFAULT_TENANT`:

```bash
# api/.env (agregar)
DEFAULT_TENANT=tastychicken
```

Con eso, `localhost:3000` activa automáticamente el schema `tastychicken` sin necesitar subdomain.
El frontend en `localhost:5173` funciona normalmente.

---

## Panel superadmin

Accedido desde `http://admin.lvh.me:3000/superadmin/tenants`.

Requiere autenticación HTTP Basic. Las credenciales se configuran en `api/.env`:

```env
SUPERADMIN_USERNAME=admin
SUPERADMIN_PASSWORD=supersecreto
```

El browser pedirá usuario y contraseña al entrar.

---

## Endpoints de la API relevantes en dev

```
GET  http://tastychicken.lvh.me:3000/up                     → health check
GET  http://tastychicken.lvh.me:3000/api/v1/store_status     → estado del local
GET  http://tastychicken.lvh.me:3000/api/v1/categories       → menú (público)
POST http://tastychicken.lvh.me:3000/api/v1/auth/google      → login con Google

GET  http://admin.lvh.me:3000/superadmin/tenants             → panel superadmin (HTTP Basic)
```

---

## Tenants de ejemplo disponibles en dev

| Subdominio | Nombre | Cómo se creó |
|---|---|---|
| `tastychicken` | Tasty Chicken | `rake tenant:create["Tasty Chicken","tastychicken"]` |

Para ver todos los tenants activos:
```bash
bin/rake tenant:list
```
