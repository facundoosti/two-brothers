# ── Seeds de desarrollo ─────────────────────────────────────────────────────────
# Crea lo mínimo para operar: settings, stock del día y usuarios base.
# El menú y las órdenes se crean manualmente desde el panel de admin.
#
# Uso:
#   DEFAULT_TENANT=tastychicken bin/rails db:seed

# ── Settings ───────────────────────────────────────────────────────────────────

puts "Creando settings..."
{
  "daily_chicken_stock" => "100",
  "store_name"          => "Two Brothers",
  "store_address"       => "Washington 133, Dolores",
  "open_days"           => "4,5,6,0",
  "opening_time"        => "20:00",
  "closing_time"        => "00:00",
  "mp_alias"            => "twobrothers.mp"
}.each { |k, v| Setting[k] = v }

# ── Stock del día ──────────────────────────────────────────────────────────────

puts "Creando stock del día..."
DailyStock.find_or_create_by!(date: Date.today) { |s| s.total = 100; s.used = 0 }

# ── Usuarios ───────────────────────────────────────────────────────────────────

puts "Creando usuarios..."
admin = User.find_or_create_by!(email: "facundo@twobrothers.com") do |u|
  u.provider  = "google"
  u.uid       = "seed_admin_001"
  u.name      = "Facundo Osti"
  u.role      = :admin
  u.status    = :active
  u.api_token = SecureRandom.hex(32)
end
admin.update!(role: :admin, status: :active)

delivery = User.find_or_create_by!(email: "carlos.mendoza@gmail.com") do |u|
  u.provider  = "google"
  u.uid       = "seed_delivery_001"
  u.name      = "Carlos Mendoza"
  u.role      = :delivery
  u.status    = :active
  u.api_token = SecureRandom.hex(32)
end

customer = User.find_or_create_by!(email: "ana.garcia@gmail.com") do |u|
  u.provider  = "google"
  u.uid       = "seed_customer_001"
  u.name      = "Ana García"
  u.role      = :customer
  u.status    = :active
  u.api_token = SecureRandom.hex(32)
end

# ── Resumen ────────────────────────────────────────────────────────────────────

puts ""
puts "Seeds completados!"
puts ""
puts "=== Usuarios ==="
puts "  Admin:    #{admin.name} (#{admin.email})"
puts "  Delivery: #{delivery.name} (#{delivery.email})"
puts "  Cliente:  #{customer.name} (#{customer.email})"
puts ""
puts "=== Tokens de acceso (solo dev) ==="
puts "  Admin:    #{admin.api_token}"
puts "  Delivery: #{delivery.api_token}"
puts "  Cliente:  #{customer.api_token}"
