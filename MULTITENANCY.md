# Multi-Tenancy — Planificación y Diseño

## Resumen ejecutivo

Two Brothers evoluciona de una aplicación single-tenant a una **plataforma SaaS multi-tenant**.
Cada empresa cliente (tenant) accede a la plataforma desde su propio subdominio:

```
tastychicken.two-brothers.shop   → tenant: tastychicken
elpollofeliz.two-brothers.shop   → tenant: elpollofeliz
two-brothers.shop                → landing/marketing page
```

El aislamiento de datos se implementa con **PostgreSQL schemas** (un schema por tenant) gestionados por la gema **`apartment`**.

---

## Modelo de datos — aislamiento por schema

| Schema | Contenido |
|---|---|
| `public` | Tabla `tenants` (registro de empresas) + tablas compartidas (no hay más por ahora) |
| `tastychicken` | Copia completa de todas las tablas del app: `users`, `orders`, `menu_items`, etc. |
| `elpollofeliz` | Idem, completamente separado |

Cada tenant tiene su propia base de datos lógica dentro del mismo servidor PostgreSQL. Un usuario de `tastychicken` **nunca** puede ver datos de `elpollofeliz`.

---

## Modelo `Tenant` (schema `public`)

```ruby
# db/migrate/TIMESTAMP_create_tenants.rb
create_table :tenants do |t|
  t.string :name,       null: false          # "Tasty Chicken"
  t.string :subdomain,  null: false, index: { unique: true }  # "tastychicken"
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
    # tastychicken.two-brothers.shop tiene 3 partes → "tastychicken"
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
Browser: GET tastychicken.two-brothers.shop/api/v1/menu_items
  │
  ▼
TenantResolver (Rack middleware)
  ├── extrae subdomain: "tastychicken"
  ├── busca Tenant en schema public
  ├── si existe → Apartment::Tenant.switch("tastychicken")
  │     └── Rails procesa la request dentro del schema "tastychicken"
  └── si no existe → 404
```

---

## Frontend — detección de tenant

El frontend detecta el tenant leyendo el subdominio del `window.location.hostname`:

```typescript
// app/src/lib/tenant.ts
export function getCurrentTenant(): string | null {
  const parts = window.location.hostname.split(".");
  // hostname: tastychicken.two-brothers.shop → 3 partes
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

Google OAuth redirige a un callback fijo. El tenant debe preservarse durante el flujo:

```
1. Usuario en tastychicken.two-brothers.shop hace click en "Login con Google"
2. Frontend redirige a: tastychicken.two-brothers.shop/auth/google_oauth2
3. TenantResolver activa el schema "tastychicken" antes de iniciar OAuth
4. OmniAuth guarda state; el callback llega a tastychicken.two-brothers.shop/auth/google_oauth2/callback
5. El token Bearer que retorna es válido solo dentro del schema "tastychicken"
```

El callback URL en Google Cloud Console debe ser:
```
https://*.two-brothers.shop/auth/google_oauth2/callback   (wildcard, si Google lo soporta)
# o uno por tenant si Google no soporta wildcards:
https://tastychicken.two-brothers.shop/auth/google_oauth2/callback
```

> **Nota:** Google OAuth no soporta wildcards en URIs de redirección. Opciones:
> - Registrar cada tenant manualmente en Google Cloud (simple pero no escala).
> - Usar un dominio fijo de callback (`two-brothers.shop/auth/callback`) y pasar el tenant como parámetro de estado.

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

Se necesita una capa de superadmin (fuera del schema de tenant) para:

- Listar todos los tenants
- Crear / desactivar tenants
- Ver métricas globales (opcional, fase 2)

```ruby
# Ruta superadmin — solo accesible desde two-brothers.shop (sin subdomain)
# config/routes.rb
namespace :superadmin do
  resources :tenants, only: [:index, :create, :update, :destroy]
end
```

El `TenantResolver` debe **no** activar ningún schema cuando no hay subdomain, permitiendo que estas rutas operen sobre `public`.

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

### Fase 3 — Frontend
- [ ] Helper `tenant.ts` (`getCurrentTenant`)
- [ ] Manejo de UI cuando no hay tenant (landing page o error 404)
- [ ] Mostrar nombre/logo del tenant en el header (opcional)

### Fase 4 — OAuth
- [ ] Definir estrategia de callback URL para múltiples tenants
- [ ] Ajustar `AuthController` para preservar tenant en el flujo OAuth

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

## Decisiones pendientes

| Decisión | Opciones | Estado |
|---|---|---|
| OAuth callback URL con múltiples tenants | (a) registrar por tenant, (b) callback unificado con state | ⏳ pendiente |
| Landing page en `two-brothers.shop` | ¿React app separada? ¿Rails views? | ⏳ pendiente |
| Plan de pricing / billing | fuera de scope inicial | ❌ fuera de scope |
| Límite de tenants por plan | fuera de scope inicial | ❌ fuera de scope |

---

## Referencias

- [`apartment` gem](https://github.com/influitive/apartment) — PostgreSQL schemas multi-tenancy para Rails
- [Apartment con Rails API](https://github.com/influitive/apartment#usage) — middleware integration
