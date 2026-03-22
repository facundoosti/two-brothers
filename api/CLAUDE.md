# Two Brothers — Backend (Rails API)

## Stack

| Capa | Tecnología |
|---|---|
| Framework | Ruby on Rails 8.0.x (API mode) |
| Base de datos | PostgreSQL |
| Jobs async | Solid Queue (sin Redis) |
| Cache | Solid Cache |
| WebSockets | Solid Cable (ActionCable) |
| Auth | Google OAuth 2.0 via `omniauth-google-oauth2` + token Bearer |
| Puerto dev | 4000 |

## Arrancar el servidor

```bash
bin/rails server -p 4000
```

## Comandos frecuentes

```bash
bin/rails db:migrate          # correr migraciones
bin/rails db:seed             # cargar datos iniciales
bin/rails routes              # ver todas las rutas
bin/rails console             # consola interactiva
bin/rails test                # correr tests
```

## Autenticación

- Todos los endpoints requieren `Authorization: Bearer <token>` salvo excepciones explícitas.
- `GET /api/v1/categories` es público (sin auth).
- El flujo OAuth: `GET /auth/google_oauth2` → Google → `GET /auth/google_oauth2/callback` → redirect al frontend con `?token=xxx`.
- El token se regenera al hacer logout (`DELETE /api/v1/session`).

## Estructura de carpetas relevante

```
app/
  controllers/
    application_controller.rb    # autenticación Bearer, Pagy::Method, render_error, pagy_meta
    auth_controller.rb           # OAuth callback
    api/v1/
      base_controller.rb
      users_controller.rb
      categories_controller.rb
      menu_items_controller.rb
      orders_controller.rb
      delivery_assignments_controller.rb
      delivery_locations_controller.rb
      sessions_controller.rb
      settings_controller.rb
      dashboard_controller.rb
      daily_stocks_controller.rb
  blueprints/                    # Blueprinter serializers
    user_blueprint.rb            # views: default, minimal
    category_blueprint.rb        # views: default, with_items
    menu_item_blueprint.rb
    order_blueprint.rb           # incluye user (minimal) + order_items
    order_item_blueprint.rb
    delivery_assignment_blueprint.rb  # views: default, with_order
    delivery_location_blueprint.rb
    daily_stock_blueprint.rb
  services/                      # Lógica de negocio extraída de controllers
    application_service.rb       # base con Result = Data.define(success, payload, error)
    orders/
      create_order_service.rb    # valida horario, stock y crea la orden
      confirm_payment_service.rb # descuenta stock y confirma
      cancel_order_service.rb    # cancela y devuelve stock si era confirmed
    delivery/
      update_assignment_status_service.rb  # in_transit / delivered
  models/
    user.rb           # enums: role (customer/delivery/admin), status (pending/active)
    order.rb          # enums: status, modality, payment_method
    order_item.rb
    menu_item.rb
    category.rb
    delivery_assignment.rb  # enum: status (assigned/in_transit/delivered)
    delivery_location.rb
    setting.rb        # clave-valor: Setting["key"], Setting["key"] = val
    daily_stock.rb    # DailyStock.today, stock.available
```

## Serialización con Blueprinter

```ruby
# Render single object
UserBlueprint.render_as_hash(user)
UserBlueprint.render_as_hash(user, view: :minimal)

# Render collection
OrderBlueprint.render_as_hash(orders)

# En el controller, render directo:
render json: OrderBlueprint.render_as_hash(@order)
```

## Paginación con Pagy

Pagy v43 — configurado en `config/initializers/pagy.rb`.

```ruby
# En controllers (Pagy::Method incluido en ApplicationController):
@pagy, records = pagy(:offset, scope)

render json: {
  data: SomeBlueprint.render_as_hash(records),
  pagy: pagy_meta(@pagy)   # helper definido en ApplicationController
}
# Los headers de paginación (page, count, etc.) se añaden automáticamente
# via after_action usando @pagy.headers_hash
```

`pagy_meta` retorna: `{ page, pages, count, limit, from, to, prev, next }`.

## Services — patrón de resultado

```ruby
result = Orders::CreateOrderService.call(user: current_user, params: order_params)

if result.success?
  render json: OrderBlueprint.render_as_hash(result.payload), status: :created
else
  render_error(result.error)
end
```

`ApplicationService::Result` es un `Data` con `.success?`, `.failure?`, `.payload`, `.error`.

## Endpoints principales

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| `GET` | `/auth/google_oauth2/callback` | público | OAuth callback |
| `DELETE` | `/api/v1/session` | autenticado | Logout |
| `GET` | `/api/v1/me` | autenticado | Usuario actual |
| `GET` | `/api/v1/categories` | público | Menú con ítems |
| `POST` | `/api/v1/orders` | customer | Crear orden |
| `GET` | `/api/v1/orders/:id` | customer/admin | Ver orden |
| `PATCH` | `/api/v1/orders/:id/confirm_payment` | admin | Confirmar pago |
| `PATCH` | `/api/v1/orders/:id/status` | admin | Cambiar estado |
| `PATCH` | `/api/v1/orders/:id/cancel` | admin | Cancelar orden |
| `POST` | `/api/v1/delivery_assignments` | admin | Asignar repartidor |
| `PATCH` | `/api/v1/delivery_assignments/:id/status` | delivery | Actualizar reparto |
| `GET` | `/api/v1/delivery_assignments/:id/latest_location` | admin/customer | Última posición GPS |
| `POST` | `/api/v1/delivery_locations` | delivery | Enviar coordenadas GPS |
| `GET` | `/api/v1/dashboard` | admin | Stats del día |
| `GET` | `/api/v1/daily_stock` | admin | Stock de hoy |
| `PATCH` | `/api/v1/daily_stock` | admin | Actualizar stock |
| `GET` | `/api/v1/settings` | admin | Ver configuración |
| `PATCH` | `/api/v1/settings` | admin | Actualizar configuración |
| `GET` | `/api/v1/users` | admin | Listar usuarios |
| `PATCH` | `/api/v1/users/:id` | admin | Cambiar rol/estado |

## Variables de entorno

Copiar `.env.example` a `.env` y completar:

```
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
FRONTEND_URL=http://localhost:5173
STORE_ADDRESS=Washington 133, Dolores, Buenos Aires, Argentina
STORE_LATITUDE=-36.3133
STORE_LONGITUDE=-57.6837
```

## Internacionalización (i18n)

El locale por defecto es `:es`. **Todo string visible al usuario debe ir en `config/locales/es.yml`**, nunca hardcodeado en el código.

### Estructura del locale

```yaml
es:
  activerecord:
    errors:
      messages:   # mensajes estándar de validaciones Rails
      models:     # overrides por modelo/atributo
  errors:         # mensajes custom de controllers y services
```

### Reglas obligatorias

- **Controllers:** usar `I18n.t("errors.<clave>")` para cualquier mensaje de error.
- **Services:** usar `I18n.t("errors.<clave>")` en los `failure(...)`.
- **Modelos:** no hardcodear `message:` en validaciones — agregar la traducción en `activerecord.errors.models.<modelo>.attributes.<atributo>.<tipo_error>`.
- **Strings con interpolación:** usar `I18n.t("errors.<clave>", variable: valor)` y `%{variable}` en el YAML.
- Al agregar un nuevo mensaje, siempre añadir la clave correspondiente en `config/locales/es.yml`.

### Ejemplo

```ruby
# ✅ Correcto
return failure(I18n.t("errors.store_closed"))
return failure(I18n.t("errors.insufficient_stock", available: stock.available))
render json: { error: I18n.t("errors.unauthorized") }, status: :unauthorized

# ❌ Incorrecto
return failure("El local está cerrado.")
render json: { error: "No autorizado" }, status: :unauthorized
```

## Autorización con Pundit

La gema `pundit` centraliza las reglas de acceso en `app/policies/`. Cada recurso tiene su policy que hereda de `ApplicationPolicy`.

### Matriz de permisos

| Recurso / Acción | `customer` | `delivery` | `admin` |
|---|---|---|---|
| `Order#index` | propias | ❌ | todas |
| `Order#show` | propia | ❌ | ✅ |
| `Order#create` | ✅ | ❌ | ✅ |
| `Order#confirm_payment/update_status/cancel` | ❌ | ❌ | ✅ |
| `DeliveryAssignment#index` | ❌ | propios | todos |
| `DeliveryAssignment#create` | ❌ | ❌ | ✅ |
| `DeliveryAssignment#update_status` | ❌ | solo el dueño | ❌ |
| `DeliveryLocation#create` | ❌ | ✅ | ❌ |
| `DeliveryLocation#latest` | si es su orden | ❌ | ✅ |
| `User#me` | ✅ | ✅ | ✅ |
| `User#index/update` | ❌ | ❌ | ✅ |
| `Category#index` | público (sin auth) | público | ✅ |
| `Category/MenuItem` write | ❌ | ❌ | ✅ |
| `Settings/Dashboard/DailyStock` | ❌ | ❌ | ✅ |

### Uso en controllers

```ruby
# Autorizar un recurso (acción = nombre del método actual)
authorize @order          # llama OrderPolicy#show? en action show
authorize @order          # llama OrderPolicy#cancel? en action cancel

# Autorizar contra la clase (para index/create sin instancia)
authorize Order           # llama OrderPolicy#index?
authorize Order, :create?

# Recursos sin modelo (headless)
authorize :dashboard, :show?
authorize :setting, :update?

# Policy diferente al record
authorize assignment, :latest?, policy_class: DeliveryLocationPolicy

# Scope de colección (aplica reglas de visibilidad)
policy_scope(Order)  # => todas (admin) | propias (customer) | ninguna (delivery)
```

### Estructura de archivos

```
app/policies/
  application_policy.rb          # base: helpers admin?/delivery?/customer?
  order_policy.rb
  delivery_assignment_policy.rb
  delivery_location_policy.rb
  user_policy.rb
  setting_policy.rb
  category_policy.rb
  menu_item_policy.rb
  dashboard_policy.rb
  daily_stock_policy.rb

spec/policies/                   # specs con Pundit RSpec matcher `permit`
```

### Error de autorización

`Pundit::NotAuthorizedError` se rescata en `ApplicationController#pundit_not_authorized` y devuelve `403 Forbidden` con `I18n.t("errors.forbidden")`.

### Tests

```ruby
require "pundit/rspec"  # ya incluido en rails_helper.rb

permissions :cancel? do
  it { expect(described_class).to permit(admin, order) }
  it { expect(described_class).not_to permit(customer, order) }
end
```

## Geocodificación de direcciones

La gema `geocoder` convierte `delivery_address` a coordenadas `latitude`/`longitude` en el modelo `Order`.

- **Servicio:** Nominatim (OpenStreetMap) — sin API key.
- **Trigger:** `after_validation :geocode`, solo si `delivery?` y `delivery_address_changed?`.
- **Cache:** Rails.cache con TTL de 1 semana (prefijo `geocoder:`).
- **Config:** `config/initializers/geocoder.rb` — User-Agent configurable via `CONTACT_EMAIL`.
- **Blueprint:** `OrderBlueprint` expone `latitude` y `longitude` en la respuesta JSON.
- **Tests:** usar `Geocoder::Lookup::Test` para no hacer requests reales en specs.

```ruby
# En factories/specs, stub geocoder para evitar llamadas HTTP:
before do
  Geocoder::Lookup::Test.add_stub("Av. Siempreviva 742", [{ "coordinates" => [-31.4167, -64.1833] }])
end
```

Variable de entorno opcional: `CONTACT_EMAIL` (se incluye en el User-Agent de Nominatim).

## Reglas de negocio clave

- **Creación de orden:** el customer crea la orden → nace en `pending_payment`. El admin verifica que el pago fue recibido (efectivo o transferencia) y llama a `confirm_payment` → pasa a `confirmed`. Solo a partir de `confirmed` el admin puede avanzar los demás estados.
- Stock: se descuenta al `confirmed`, se devuelve al `cancelled` (si era `confirmed`).
- Máximo 4 pollos por orden.
- Solo admin puede cancelar. Solo desde `pending_payment` o `confirmed`.
- Órdenes creadas desde mostrador nacen directamente en `confirmed`.
- Horario configurable desde `Setting["open_days"]`, `"opening_time"`, `"closing_time"`.
- `DailyStock.today` crea el registro del día automáticamente si no existe.

## Flujo de estados de una orden

```
pending_payment ──[admin: confirm_payment]──► confirmed
confirmed       ──[admin: update_status]────► preparing
preparing       ──[admin: update_status]────► ready
ready           ──[admin: update_status]────► delivering
delivering      ──[delivery: assignment]────► delivered
```

| Transición | Responsable | Endpoint |
|---|---|---|
| `pending_payment → confirmed` | Admin | `PATCH /orders/:id/confirm_payment` |
| `confirmed → preparing` | Admin | `PATCH /orders/:id/status {status: "preparing"}` |
| `preparing → ready` | Admin | `PATCH /orders/:id/status {status: "ready"}` |
| `ready → delivering` | Admin | `PATCH /orders/:id/status {status: "delivering"}` |
| `delivering → delivered` | Repartidor | `PATCH /delivery_assignments/:id/status {status: "delivered"}` |
| cualquier estado cancelable → `cancelled` | Admin (solo) | `PATCH /orders/:id/cancel` |

**Importante:** `delivered` no está disponible en `OrdersController#update_status` (admin no puede marcarlo directamente). Lo dispara `UpdateAssignmentStatusService` cuando el repartidor completa su entrega — llama internamente a `order.mark_delivered!`.

## Pagos

- **Medios aceptados:** efectivo en mano o transferencia bancaria al alias CVU de Mercado Pago configurado en `Setting["mp_alias"]`.
- **Sin integración de pagos online.** No hay Checkout Pro, Checkout API ni webhooks de MP.
- El admin confirma el pago manualmente desde el panel (`confirm_payment`) una vez verificado el cobro.
