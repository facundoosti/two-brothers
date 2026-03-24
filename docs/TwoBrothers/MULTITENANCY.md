# Multi-Tenancy — Planificación y Diseño

## Resumen ejecutivo

Two Brothers evoluciona de una aplicación single-tenant a una **plataforma SaaS multi-tenant**.
Cada empresa cliente (tenant) accede a la plataforma desde su propio subdominio:

```
laparrilla.two-brothers.shop     → tenant: laparrilla (app de la empresa)
pizzerianonna.two-brothers.shop  → tenant: pizzerianonna (app de la empresa)
two-brothers.shop                → landing page de marketing
admin.two-brothers.shop          → panel superadmin (gestión de tenants)
```

El aislamiento de datos se implementa con **PostgreSQL schemas** (un schema por tenant) gestionados por la gema **`apartment`**.

---

## Desarrollo local

### Estrategia: `lvh.me` como default + variable de entorno como fallback

**`lvh.me`** es un dominio público que resuelve a `127.0.0.1`. No requiere instalación ni configuración. Permite trabajar con subdominios reales en local:

```
laparrilla.lvh.me:3000   →  app del tenant "laparrilla"
admin.lvh.me:3000          →  panel superadmin
lvh.me:3000                →  landing page

# Frontend (Vite)
laparrilla.lvh.me:5173   →  frontend apuntando al tenant "laparrilla"
```

**Fallback — variable de entorno** (para cuando no hay internet):

```env
# api/.env
DEFAULT_TENANT=laparrilla
```

El `TenantResolver` usa `DEFAULT_TENANT` si no detecta subdomain y el entorno es `development`:

```ruby
subdomain = extract_subdomain(request)
subdomain ||= ENV["DEFAULT_TENANT"] if Rails.env.development?
```

### Variables de entorno frontend en desarrollo

```env
# app/.env
VITE_API_BASE_URL=http://lvh.me:3000
```

El frontend construye la URL de la API usando el mismo host del browser (mismo origen), por lo que `laparrilla.lvh.me:5173` apunta automáticamente a `laparrilla.lvh.me:3000`.

### Resumen rápido para arrancar a desarrollar

```bash
# 1. Levantar backend
cd api && bin/rails server -p 3000

# 2. Levantar frontend
cd app && npm run dev -- --host lvh.me

# 3. Abrir en el browser
open http://laparrilla.lvh.me:5173
```

---

## Modelo de datos — aislamiento por schema

| Schema | Contenido |
|---|---|
| `public` | Tabla `tenants` (registro de empresas) + tablas compartidas (no hay más por ahora) |
| `laparrilla` | Copia completa de todas las tablas del app: `users`, `orders`, `menu_items`, etc. |
| `pizzerianonna` | Idem, completamente separado |

Cada tenant tiene su propia base de datos lógica dentro del mismo servidor PostgreSQL. Un usuario de `laparrilla` **nunca** puede ver datos de `pizzerianonna`.

---

## Modelo `Tenant` (schema `public`)

```ruby
# db/migrate/TIMESTAMP_create_tenants.rb
create_table :tenants do |t|
  t.string :name,       null: false          # "La Parrilla"
  t.string :subdomain,  null: false, index: { unique: true }  # "laparrilla"
  t.string :plan,       default: "basic"     # para billing futuro
  t.boolean :active,    default: true
  t.timestamps
end
```

```ruby
# app/models/tenant.rb
class Tenant < ApplicationRecord
  validates :subdomain, presence: true, uniqueness: true,
                        format: { with: /\A[a-z0-9\-]+\z/ }

  def self.find_by_subdomain!(subdomain)
    find_by!(subdomain: subdomain, active: true)
  end
end
```

---

## Configuración de `apartment`

### Gemfile

```ruby
gem "apartment"
```

### Initializer

```ruby
# config/initializers/apartment.rb
Apartment.configure do |config|
  # Tablas que viven en public y NO se replican por tenant
  config.excluded_models = %w[Tenant]

  # Obtener lista de tenants para migraciones masivas
  config.tenant_names = -> { Tenant.pluck(:subdomain) }

  # Usar schemas de PostgreSQL (default y recomendado)
  config.use_schemas = true
end
```

---

## Resolución de tenant por subdominio

### Middleware de Rack

```ruby
# app/middleware/tenant_resolver.rb
class TenantResolver
  RESERVED_SUBDOMAINS = %w[www api admin].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    request   = ActionDispatch::Request.new(env)
    subdomain = extract_subdomain(request)

    if subdomain.present? && RESERVED_SUBDOMAINS.exclude?(subdomain)
      tenant = Tenant.find_by(subdomain: subdomain, active: true)

      if tenant
        Apartment::Tenant.switch(subdomain) { @app.call(env) }
      else
        [404, { "Content-Type" => "application/json" },
         ['{"error":"Tenant not found"}']]
      end
    else
      @app.call(env)  # landing page o rutas sin tenant
    end
  end

  private

  def extract_subdomain(request)
    # two-brothers.shop tiene 2 partes → subdomain vacío
    # laparrilla.two-brothers.shop tiene 3 partes → "laparrilla"
    parts = request.host.split(".")
    return nil if parts.length <= 2

    parts.first
  end
end
```

### Registro del middleware

```ruby
# config/application.rb
config.middleware.use TenantResolver
```

---

## Flujo completo de una request

```
Browser: GET laparrilla.two-brothers.shop/api/v1/menu_items
  │
  ▼
TenantResolver (Rack middleware)
  ├── extrae subdomain: "laparrilla"
  ├── busca Tenant en schema public
  ├── si existe → Apartment::Tenant.switch("laparrilla")
  │     └── Rails procesa la request dentro del schema "laparrilla"
  └── si no existe → 404
```

---

## Frontend — detección de tenant

El frontend detecta el tenant leyendo el subdominio del `window.location.hostname`:

```typescript
// app/src/lib/tenant.ts
export function getCurrentTenant(): string | null {
  const parts = window.location.hostname.split(".");
  // hostname: laparrilla.two-brothers.shop → 3 partes
  // hostname: localhost → 1 parte (dev sin tenant)
  if (parts.length < 3) return null;
  return parts[0];
}

export function hasTenant(): boolean {
  return getCurrentTenant() !== null;
}
```

El `api.ts` no necesita cambios: la URL base apunta al mismo origen, y el subdominio viaja automáticamente en cada request HTTP.

### Variables de entorno frontend

```env
# app/.env
VITE_APP_DOMAIN=two-brothers.shop
```

---

## Provisionamiento de un nuevo tenant

Flujo para dar de alta una empresa:

```
1. Superadmin crea el Tenant en public (POST /superadmin/tenants)
2. Apartment crea el schema PostgreSQL automáticamente
3. Se corren las migraciones en el nuevo schema
4. (Opcional) Se ejecuta un seed básico: categorías default, configuración inicial
5. El subdomain queda activo: empresa.two-brothers.shop ya funciona
```

### Rake task de provisión

```ruby
# lib/tasks/tenant.rake
namespace :tenant do
  desc "Crear nuevo tenant: rake tenant:create[nombre,subdominio]"
  task :create, [:name, :subdomain] => :environment do |_, args|
    tenant = Tenant.create!(name: args[:name], subdomain: args[:subdomain])
    Apartment::Tenant.create(tenant.subdomain)
    puts "✅ Tenant '#{tenant.subdomain}' creado correctamente."
  end

  desc "Migrar todos los tenants"
  task migrate: :environment do
    Apartment::Tenant.each do |subdomain|
      puts "→ Migrando #{subdomain}..."
      Apartment::Tenant.switch(subdomain) { ActiveRecord::Migration.check_all_pending! }
    end
  end
end
```

---

## Migraciones

`apartment` replica automáticamente cada migración nueva en todos los schemas existentes al correr `db:migrate`. No se requiere nada especial salvo:

- Las migraciones que afecten **solo a `public`** (ej: tabla `tenants`) deben excluirse de la replicación con `connection.execute("SET search_path TO public")`.
- Las tablas en `excluded_models` nunca se replican.

```ruby
# Ejemplo: migración solo en public
class CreateTenants < ActiveRecord::Migration[8.0]
  def change
    # Esta migración corre solo en el schema en que se ejecuta (public)
    # Apartment no la replicará porque Tenant está en excluded_models
    create_table :tenants do |t|
      # ...
    end
  end
end
```

---

## Autenticación OAuth por tenant

**Decisión: callback unificado con parámetro `state`.**

Google OAuth no soporta wildcards en URIs de redirección. Se usa un único callback registrado en Google Cloud Console y el tenant viaja en el parámetro `state` del flujo OAuth.

### URL registrada en Google Cloud Console

```
https://two-brothers.shop/auth/google_oauth2/callback
```

### Flujo completo

```
1. Usuario en laparrilla.two-brothers.shop hace click en "Login con Google"
2. Frontend construye la URL de OAuth incluyendo el tenant en el state:
     GET two-brothers.shop/auth/google_oauth2?tenant=laparrilla
3. AuthController codifica el tenant en el parámetro `state` de OmniAuth
4. Google autentica y redirige a: two-brothers.shop/auth/google_oauth2/callback?state=...
5. TenantResolver no activa schema (estamos en two-brothers.shop sin subdomain)
6. AuthController decodifica el tenant del `state`, activa el schema con
     Apartment::Tenant.switch(tenant) { ... }
   y crea/actualiza el usuario dentro de ese schema
7. Retorna redirect al frontend: laparrilla.two-brothers.shop?token=xxx
```

### Implementación en AuthController

```ruby
# Paso 2 — el frontend agrega ?tenant= antes de iniciar OAuth
# OmniAuth lo incluye en el state automáticamente si se pasa como query param
# o se puede setear manualmente en el initializer de omniauth

# Paso 6 — en el callback
def callback
  tenant_subdomain = extract_tenant_from_state(request.env["omniauth.params"])

  Apartment::Tenant.switch(tenant_subdomain) do
    # lógica existente de creación/login de usuario
    user = User.find_or_create_from_omniauth(auth)
    redirect_to "https://#{tenant_subdomain}.two-brothers.shop?token=#{user.auth_token}"
  end
end
```

---

## DNS y certificado SSL

### Wildcard DNS

```
*.two-brothers.shop  →  IP del servidor (Railway / VPS)
two-brothers.shop    →  IP del servidor
```

### Wildcard SSL

Usar Let's Encrypt con un certificado wildcard `*.two-brothers.shop`.
En Railway esto se configura como custom domain con wildcard en el proyecto.

---

## Superadmin — gestión de tenants

**Decisión: panel en `admin.two-brothers.shop` con auth usuario/contraseña via variables de entorno.**

Accesible solo para el operador de la plataforma (no es un rol dentro de ningún tenant).
Permite dar de alta y gestionar empresas/subdomios.

### Autenticación superadmin

Sin Google OAuth. Credenciales fijas en variables de entorno del backend:

```env
SUPERADMIN_USERNAME=admin
SUPERADMIN_PASSWORD=supersecretpassword
```

El `TenantResolver` identifica `admin.two-brothers.shop` como subdominio reservado y **no activa ningún schema de tenant** — las rutas superadmin operan directamente sobre `public`.

```ruby
# app/middleware/tenant_resolver.rb
RESERVED_SUBDOMAINS = %w[www api admin].freeze
```

### Autenticación HTTP Basic para las rutas superadmin

```ruby
# app/controllers/superadmin/base_controller.rb
class Superadmin::BaseController < ActionController::API
  before_action :authenticate_superadmin!

  private

  def authenticate_superadmin!
    authenticate_or_request_with_http_basic("Superadmin") do |user, pass|
      ActiveSupport::SecurityUtils.secure_compare(user, ENV["SUPERADMIN_USERNAME"]) &
        ActiveSupport::SecurityUtils.secure_compare(pass, ENV["SUPERADMIN_PASSWORD"])
    end
  end
end
```

### Rutas

```ruby
# config/routes.rb
namespace :superadmin do
  resources :tenants, only: [:index, :create, :update, :destroy]
end
```

### Acciones del panel superadmin

| Acción | Descripción |
|---|---|
| Listar tenants | Ver todas las empresas, estado activo/inactivo |
| Crear tenant | Nombre + subdomain → provisiona schema automáticamente |
| Activar / desactivar | Habilita o bloquea el acceso al subdominio |
| (Fase 2) Métricas | Órdenes totales por tenant, actividad reciente |

---

## Plan de implementación (fases)

### Fase 1 — Infraestructura base (Backend)
- [ ] Instalar gema `apartment`
- [ ] Crear migración y modelo `Tenant`
- [ ] Configurar `config/initializers/apartment.rb`
- [ ] Implementar middleware `TenantResolver`
- [ ] Registrar middleware en `config/application.rb`
- [ ] Rake tasks: `tenant:create`, `tenant:migrate`
- [ ] Tests del middleware con subdominio válido, inválido y ausente

### Fase 2 — Provisionamiento
- [ ] Controller `superadmin/tenants_controller.rb` (CRUD básico)
- [ ] Seed por tenant: configuración inicial, categorías ejemplo
- [ ] Script de migración para convertir el tenant actual (si existe data) al nuevo schema

### Fase 3 — Frontend (app tenant)
- [ ] Helper `tenant.ts` (`getCurrentTenant`)
- [ ] Ajustar inicio de flujo OAuth para pasar `?tenant=` en la URL
- [ ] Manejo de UI cuando no hay tenant (redirigir a landing)
- [ ] Mostrar nombre/logo del tenant en el header (opcional, Fase 2)

### Fase 4 — OAuth
- [ ] Ajustar `AuthController#callback` para leer tenant del `state`
- [ ] `Apartment::Tenant.switch` dentro del callback
- [ ] Redirect post-login al subdominio correcto del tenant

### Fase 5 — Panel superadmin
- [ ] `Superadmin::BaseController` con HTTP Basic auth via ENV
- [ ] `Superadmin::TenantsController` (index, create, update, destroy)
- [ ] Frontend mínimo para el panel (puede ser HTML+ERB o React separado — decidir)

### Fase 6 — Landing page (`two-brothers.shop`)
- [ ] Diseño y contenido de la landing de marketing
- [ ] Decidir tech: React separado o Rails views estáticas

### Fase 5 — Infraestructura / DNS
- [ ] Configurar wildcard DNS en el registrador de `two-brothers.shop`
- [ ] Configurar wildcard SSL (Let's Encrypt o Railway)
- [ ] Verificar CORS en Rails para `*.two-brothers.shop`

---

## CORS — configuración para subdominio wildcard

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ->(source, _env) {
      source.match?(/\Ahttps?:\/\/([a-z0-9\-]+\.)?two-brothers\.shop(:\d+)?\z/)
    }
    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
```

---

## Decisiones

| Decisión | Resolución |
|---|---|
| OAuth callback URL | ✅ Callback unificado en `two-brothers.shop`, tenant viaja en `state` |
| Landing `two-brothers.shop` | ✅ Landing page de marketing |
| Panel superadmin | ✅ `admin.two-brothers.shop`, auth HTTP Basic con credenciales en ENV |
| Tech del panel superadmin | ✅ Rails ERB (vistas HTML simples, sin frontend separado) |
| Tech de la landing | ✅ Rails ERB (vistas HTML simples, sin frontend separado) |
| Plan de pricing / billing | ❌ fuera de scope |
| Límite de tenants por plan | ❌ fuera de scope |

---

## Referencias

- [`apartment` gem](https://github.com/influitive/apartment) — PostgreSQL schemas multi-tenancy para Rails
- [Apartment con Rails API](https://github.com/influitive/apartment#usage) — middleware integration
