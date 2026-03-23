# Infraestructura — Two Brothers

## Decisión

| Servicio | Proveedor | Plan | Costo |
|---|---|---|---|
| **Compute (API + Frontend)** | [Railway](https://railway.app) | Hobby | ~$5/mes |
| **PostgreSQL** | [Supabase](https://supabase.com) | Free | $0 |
| **Storage (archivos/imágenes)** | [Supabase Storage](https://supabase.com/storage) | Free | $0 |

### Por qué Railway sobre Render

- Usa el `Dockerfile` existente sin cambios.
- Los servicios **no duermen** en plan Hobby (Render free duerme tras 15 min — rompe Solid Cable/WebSockets).
- PostgreSQL de Render free expira a los 90 días.
- El crédito mensual de $5 cubre el uso típico de una beta pequeña.

---

## Arquitectura de servicios

```
Railway Project: two-brothers
├── api          ← Ruby on Rails 8 (Dockerfile)
└── app          ← React + Vite (static build, dist/)

Supabase Project: two-brothers
├── PostgreSQL   ← primary + cache + queue + cable (mismo proyecto, distinto DATABASE_URL)
└── Storage      ← Active Storage (S3-compatible)
```

---

## Supabase — PostgreSQL

### El problema de los 4 databases de Rails 8

Rails 8 con Solid Queue/Cache/Cable usa 4 databases separadas en `config/database.yml`
(`primary`, `cache`, `queue`, `cable`). Supabase free ofrece **1 proyecto con 1 instancia
PostgreSQL**. La solución es apuntar todos al mismo host pero con distinto `database` name,
o más simple: usar el mismo database y dejar que Rails genere las tablas en el mismo schema.

**Opción recomendada para beta: un único database de Supabase con las tablas conviviendo.**
Cambiar `database.yml` en producción para que `cache`, `queue` y `cable` reutilicen el
mismo `DATABASE_URL` que el primary:

```yaml
# config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  prepared_statements: false   # ← OBLIGATORIO con PgBouncer (Supabase pooler)
  advisory_locks: false        # ← OBLIGATORIO con PgBouncer en transaction mode

production:
  primary: &primary_production
    <<: *default
    url: <%= ENV["DATABASE_URL"] %>          # Supabase pooler (puerto 6543)
  cache:
    <<: *primary_production
    migrations_paths: db/cache_migrate
  queue:
    <<: *primary_production
    migrations_paths: db/queue_migrate
  cable:
    <<: *primary_production
    migrations_paths: db/cable_migrate
```

> `prepared_statements: false` y `advisory_locks: false` son **obligatorios** cuando se
> usa el pooler de Supabase (PgBouncer en transaction mode). Sin esto, Rails lanza errores
> al hacer prepared statements o cuando Solid Queue toma advisory locks.

### URLs de conexión en Supabase

Supabase expone dos URLs. Cada una tiene un rol distinto:

| URL | Puerto | Cuándo usarla |
|---|---|---|
| **Session/Transaction pooler** | 6543 | Runtime de la app (requests normales) |
| **Direct connection** | 5432 | Migraciones (`db:migrate`) |

```bash
# Variables de entorno en Railway

# Runtime — via PgBouncer pooler (transaction mode)
DATABASE_URL=postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres

# Migraciones — direct connection sin pooler
DIRECT_DATABASE_URL=postgresql://postgres:[password]@db.[ref].supabase.co:5432/postgres
```

### Comando de deploy en Railway (API service)

En el panel de Railway → API service → Settings → Deploy → Custom Start Command:

```bash
bundle exec rails db:migrate && bin/thrust bin/rails server
```

Las migraciones deben usar la direct connection. Configurar en `config/database.yml` o
pasar `DATABASE_URL=$DIRECT_DATABASE_URL bundle exec rails db:migrate` si se usa un
pre-deploy command separado.

### `apartment` (multi-tenancy) y Supabase

El gem `apartment` crea PostgreSQL **schemas** por tenant (`CREATE SCHEMA tenant_name`).
Esto funciona sin problemas sobre una instancia Supabase standard.

**Restricciones:**
- Las migraciones de `apartment` (`apartment:migrate`) **deben correr contra la direct
  connection** (puerto 5432), no el pooler. `CREATE SCHEMA` requiere advisory locks.
- Asegurarse de tener `DIRECT_DATABASE_URL` disponible al correr migraciones en el deploy.

---

## Supabase — Storage (Active Storage)

Supabase Storage expone una API **compatible con S3**. Active Storage puede usarla con el
adapter `:S3` estándar.

### Gem necesaria

```ruby
# Gemfile
gem "aws-sdk-s3", require: false
```

### config/storage.yml

```yaml
supabase:
  service: S3
  access_key_id: <%= ENV["SUPABASE_STORAGE_KEY"] %>
  secret_access_key: <%= ENV["SUPABASE_STORAGE_SECRET"] %>
  region: auto
  bucket: <%= ENV["SUPABASE_BUCKET"] %>
  endpoint: https://<project-ref>.supabase.co/storage/v1/s3
  force_path_style: true
```

Reemplazar `<project-ref>` con el ref del proyecto Supabase (visible en Settings → General).

### config/environments/production.rb

```ruby
config.active_storage.service = :supabase
```

### Cómo obtener las credenciales en Supabase

1. Dashboard → Storage → crear un bucket (ej: `two-brothers`, público o privado según necesidad).
2. Settings → Storage → S3 Connection → copiar **Access Key** y **Secret Key**.
3. Esas son `SUPABASE_STORAGE_KEY` y `SUPABASE_STORAGE_SECRET`.

---

## Railway — Servicios

### API service (Rails)

| Campo | Valor |
|---|---|
| Source | GitHub repo → carpeta `api/` (Root Directory: `api`) |
| Builder | Dockerfile (auto-detectado) |
| Expose port | 80 (ya en el Dockerfile: `EXPOSE 80`) |
| Start command | `bundle exec rails db:migrate && bin/thrust bin/rails server` |

### App service (Frontend)

| Campo | Valor |
|---|---|
| Source | GitHub repo → carpeta `app/` (Root Directory: `app`) |
| Builder | Nixpacks (Node.js auto-detectado) |
| Build command | `npm run build` |
| Start command | `npx serve dist` (o configurar como static site) |

> Alternativa más simple: usar Railway's static site deploy directo desde el `dist/` del build.

### Variables de entorno — API service (Railway)

```bash
RAILS_ENV=production
RAILS_MASTER_KEY=<contenido de config/master.key>

# Auth
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...

# URLs
FRONTEND_URL=https://app.two-brothers.shop
STORE_ADDRESS=Washington 133, Dolores, Buenos Aires, Argentina
STORE_LATITUDE=-36.3133
STORE_LONGITUDE=-57.6837

# Supabase DB
DATABASE_URL=postgresql://postgres.[ref]:[pw]@aws-0-[region].pooler.supabase.com:6543/postgres
DIRECT_DATABASE_URL=postgresql://postgres:[pw]@db.[ref].supabase.co:5432/postgres

# Supabase Storage
SUPABASE_STORAGE_KEY=...
SUPABASE_STORAGE_SECRET=...
SUPABASE_BUCKET=two-brothers
```

### Variables de entorno — App service (Railway)

```bash
VITE_API_URL=https://<railway-api-domain>.up.railway.app
```

---

## Dominios

El dominio `two-brothers.shop` (o subdominio) se configura en Railway → cada service →
Settings → Networking → Custom Domain.

| Service | Dominio sugerido |
|---|---|
| API | `api.two-brothers.shop` |
| Frontend | `app.two-brothers.shop` o `two-brothers.shop` |

El multi-tenancy por subdominio (`{empresa}.two-brothers.shop`) requiere un **wildcard DNS**
apuntando al servicio de frontend (o al API si el resolver es server-side).

---

## Límites del free tier de Supabase

| Recurso | Límite free |
|---|---|
| Base de datos | 500 MB |
| Storage | 1 GB |
| Bandwidth | 5 GB/mes |
| Proyectos activos | 2 |
| Pausa por inactividad | Sí, tras 1 semana sin requests (en free) |

> La pausa por inactividad de Supabase free aplica al **proyecto completo**, incluyendo la DB.
> Para evitarla en beta, hacer al menos 1 request por semana o upgradear a Pro ($25/mes).
> Un cron job en Railway que haga ping al API cada pocos días es suficiente para mantenerlo activo.

---

## Checklist de deploy

### Supabase
- [ ] Crear proyecto en supabase.com
- [ ] Copiar `DATABASE_URL` (pooler, puerto 6543) y `DIRECT_DATABASE_URL` (direct, puerto 5432)
- [ ] Crear bucket en Storage (`two-brothers`)
- [ ] Copiar S3 credentials (Storage → S3 Connection)
- [ ] Verificar que el proyecto no esté pausado antes del primer deploy

### Rails (`api/`)
- [ ] Actualizar `config/database.yml` production con `prepared_statements: false` y `advisory_locks: false`
- [ ] Agregar `gem "aws-sdk-s3", require: false` al Gemfile
- [ ] Configurar `config/storage.yml` con el adapter Supabase
- [ ] Configurar `config/environments/production.rb` → `config.active_storage.service = :supabase`
- [ ] Asegurarse de tener `RAILS_MASTER_KEY` en Railway (nunca commitear `master.key`)

### Railway
- [ ] Crear proyecto `two-brothers`
- [ ] Crear service `api` → conectar repo → Root Directory: `api`
- [ ] Crear service `app` → conectar repo → Root Directory: `app`
- [ ] Cargar todas las variables de entorno en cada service
- [ ] Verificar que el Dockerfile sea detectado en `api`
- [ ] Configurar dominios custom (si aplica)
- [ ] Primer deploy → revisar logs para confirmar que las migraciones corren OK
