# Seed mínimo que se ejecuta al provisionar un nuevo tenant.
# Crea la configuración inicial necesaria para que la plataforma funcione.
# El dueño del negocio personaliza estos valores desde el panel de settings.
#
# Uso:
#   Apartment::Tenant.switch("tastychicken") { load Rails.root.join("db/seeds/tenant_seed.rb") }

store_name = defined?(TENANT_NAME) ? TENANT_NAME : "Mi Tienda"

puts "  → Creando settings para '#{store_name}'..."
{
  "store_name"    => store_name,
  "store_address" => "",
  "open_days"     => "4,5,6,0",
  "opening_time"  => "20:00",
  "closing_time"  => "00:00",
  "mp_alias"      => ""
}.each { |k, v| Setting[k] = v }

puts "  → Creando usuarios de desarrollo..."
admin = User.find_or_create_by!(uid: "seed_admin_001") do |u|
  u.email     = "facundo@twobrothers.com"
  u.provider  = "google"
  u.name      = "Facundo Osti"
  u.role      = :admin
  u.status    = :active
  u.api_token = SecureRandom.hex(32)
end
admin.update!(role: :admin, status: :active)

delivery = User.find_or_create_by!(uid: "seed_delivery_001") do |u|
  u.email     = "carlos.mendoza@gmail.com"
  u.provider  = "google"
  u.name      = "Carlos Mendoza"
  u.role      = :delivery
  u.status    = :active
  u.api_token = SecureRandom.hex(32)
end

customer = User.find_or_create_by!(uid: "seed_customer_002") do |u|
  u.email     = "lucas.fernandez@gmail.com"
  u.provider  = "google"
  u.name      = "Lucas Fernández"
  u.role      = :customer
  u.status    = :active
  u.api_token = SecureRandom.hex(32)
end

puts ""
puts "  === Tokens de acceso (solo dev) ==="
puts "  Admin:    #{admin.api_token}"
puts "  Delivery: #{delivery.api_token}"
puts "  Cliente:  #{customer.api_token}"
puts ""
puts "  ✅ Tenant '#{store_name}' inicializado."
