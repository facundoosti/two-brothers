# Guía de onboarding — Crear una empresa nueva

Esta guía explica cómo dar de alta una empresa (tenant) en la plataforma desde cero.

---

## Prerequisitos

- Acceso SSH al servidor (o consola de Railway)
- Variables de entorno configuradas: `SUPERADMIN_USERNAME`, `SUPERADMIN_PASSWORD`
- Base de datos corriendo con las migraciones al día

---

## Opción A — Panel web (recomendado)

1. Acceder a `https://admin.two-brothers.shop/superadmin/tenants`
2. Ingresar con usuario y contraseña de superadmin
3. Hacer click en **"Nueva empresa"**
4. Completar:
   - **Nombre**: nombre visible de la empresa (ej: `Tasty Chicken`)
   - **Subdominio**: identificador único en minúsculas, solo letras, números y guiones (ej: `tastychicken`)
5. Confirmar. El sistema automáticamente:
   - Crea el schema PostgreSQL `tastychicken`
   - Migra todas las tablas al nuevo schema
   - Ejecuta el seed inicial (settings, categorías base, stock del día)
6. El subdominio queda operativo: `https://tastychicken.two-brothers.shop`

---

## Opción B — Rake task (consola / deploy)

```bash
# Producción (Railway console o SSH)
bin/rake "tenant:create[Tasty Chicken,tastychicken]"
```

Salida esperada:
```
  → Creando settings para 'Tasty Chicken'...
  → Creando categorías base...
  → Creando stock del día...
  ✅ Tenant 'tastychicken' (Tasty Chicken) creado correctamente.
```

---

## Qué queda configurado automáticamente

| Dato | Valor inicial | Dónde cambiarlo |
|---|---|---|
| Nombre del local | El nombre ingresado | Panel → Settings |
| Dirección | "Configurar dirección" | Panel → Settings |
| Stock diario | 100 unidades | Panel → Settings |
| Días de apertura | Jue-Dom (4,5,6,0) | Panel → Settings |
| Horario | 20:00 – 00:00 | Panel → Settings |
| Alias Mercado Pago | "configurar.mp" | Panel → Settings |
| Categorías | Principal, Adicionales, Bebidas | Panel → Menú |

---

## Qué NO se crea automáticamente (el dueño lo configura)

- **Usuarios**: el primer admin debe loguearse con Google OAuth. Una vez creado como `pending`, un superadmin (o el mismo usuario con acceso directo a la DB) debe asignarle el rol `admin` desde el panel de usuarios.
- **Ítems del menú**: el admin del tenant los crea desde el panel.
- **Imágenes**: el admin las sube desde el panel de menú.

---

## Primer acceso del admin del tenant

1. El dueño del negocio entra a `https://tastychicken.two-brothers.shop/login`
2. Hace login con Google
3. Su cuenta queda en estado `pending` (sin rol asignado)
4. El superadmin debe asignarle rol `admin`:

```bash
# Desde la consola del servidor
bin/rails runner "
  Apartment::Tenant.switch('tastychicken') do
    user = User.find_by!(email: 'dueno@email.com')
    user.update!(role: :admin, status: :active)
    puts 'Rol asignado: ' + user.email
  end
"
```

---

## Desactivar / reactivar una empresa

```bash
# Desactivar (bloquea el acceso al subdominio → 404)
bin/rails runner "Tenant.find_by!(subdomain: 'tastychicken').update!(active: false)"

# Reactivar
bin/rails runner "Tenant.find_by!(subdomain: 'tastychicken').update!(active: true)"
```

O desde el panel superadmin: toggle "Activo/Inactivo" en la tabla de empresas.

---

## Eliminar una empresa (irreversible)

```bash
bin/rake "tenant:drop[tastychicken]"
```

⚠️ Esto elimina el schema PostgreSQL completo con todos los datos del tenant. No hay rollback.

---

## Verificar estado de todos los tenants

```bash
bin/rake tenant:list
```

```
Subdominio           Nombre                         Activo   Creado
------------------------------------------------------------------------
tastychicken         Tasty Chicken                  sí       2026-03-23
elpollofeliz         El Pollo Feliz                 sí       2026-03-24
```
