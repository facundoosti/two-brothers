# Seed mínimo que se ejecuta al provisionar un nuevo tenant.
# Crea la configuración inicial necesaria para que la plataforma funcione.
# El dueño del negocio personaliza estos valores desde el panel de settings.
#
# Uso:
#   Apartment::Tenant.switch("tastychicken") { load Rails.root.join("db/seeds/tenant_seed.rb") }

store_name = defined?(TENANT_NAME) ? TENANT_NAME : "Mi Tienda"

puts "  → Creando settings para '#{store_name}'..."
{
  "store_name"          => store_name,
  "store_address"       => "",
  "daily_chicken_stock" => "100",
  "open_days"           => "4,5,6,0",
  "opening_time"        => "20:00",
  "closing_time"        => "00:00",
  "mp_alias"            => ""
}.each { |k, v| Setting[k] = v }

puts "  → Creando stock del día..."
DailyStock.find_or_create_by!(date: Date.today) { |s| s.total = 100; s.used = 0 }

puts "  ✅ Tenant '#{store_name}' inicializado."
