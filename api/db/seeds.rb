# ── Helpers ────────────────────────────────────────────────────────────────────

def create_order(user:, modality:, payment_method:, total:, status:, items:, created_at: Time.current, delivery_address: nil, created_by: nil, cancelled_by: nil, cancelled_at: nil, cancellation_reason: nil)
  order = Order.create!(
    user: user,
    modality: modality,
    payment_method: payment_method,
    total: total,
    status: status,
    delivery_address: delivery_address,
    created_by: created_by,
    cancelled_by: cancelled_by,
    cancelled_at: cancelled_at,
    cancellation_reason: cancellation_reason,
    created_at: created_at,
    updated_at: created_at
  )
  items.each { |attrs| order.order_items.create!(**attrs) }
  order
end

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

# ── Categorías y menú ──────────────────────────────────────────────────────────

puts "Creando categorías y menú..."
pollo       = Category.find_or_create_by!(name: "Pollos")      { |c| c.position = 1 }
adicionales = Category.find_or_create_by!(name: "Adicionales") { |c| c.position = 2 }
bebidas     = Category.find_or_create_by!(name: "Bebidas")     { |c| c.position = 3 }

pollo_entero = MenuItem.find_or_create_by!(name: "Pollo Entero", category: pollo) do |i|
  i.description = "Pollo entero al espiedo con papas"
  i.price = 8_500
  i.available = true
end

medio_pollo = MenuItem.find_or_create_by!(name: "Medio Pollo", category: pollo) do |i|
  i.description = "Medio pollo al espiedo con papas"
  i.price = 4_500
  i.available = true
end

cuarto_pollo = MenuItem.find_or_create_by!(name: "Cuarto de Pollo", category: pollo) do |i|
  i.description = "Cuarto de pollo, ideal para una persona"
  i.price = 2_500
  i.available = false
end

papas = MenuItem.find_or_create_by!(name: "Papas Fritas", category: adicionales) do |i|
  i.description = "Porción de papas fritas"
  i.price = 1_500
  i.available = true
end

ensalada = MenuItem.find_or_create_by!(name: "Ensalada Mixta", category: adicionales) do |i|
  i.description = "Lechuga, tomate y zanahoria"
  i.price = 1_200
  i.available = true
end

coca = MenuItem.find_or_create_by!(name: "Coca-Cola 500ml", category: bebidas) do |i|
  i.description = "Gaseosa fría"
  i.price = 900
  i.available = true
end

agua = MenuItem.find_or_create_by!(name: "Agua Mineral 500ml", category: bebidas) do |i|
  i.description = "Agua sin gas fría"
  i.price = 700
  i.available = true
end

# ── Stock del día ──────────────────────────────────────────────────────────────

puts "Creando stock del día..."
stock = DailyStock.find_or_create_by!(date: Date.today) { |s| s.total = 100; s.used = 0 }

# ── Usuarios ───────────────────────────────────────────────────────────────────

puts "Creando usuarios..."
admin = User.find_or_create_by!(email: "admin@twobrothers.com") do |u|
  u.provider   = "google"
  u.uid        = "seed_admin_001"
  u.name       = "Admin Two Brothers"
  u.role       = :admin
  u.status     = :active
  u.api_token  = SecureRandom.hex(32)
end

delivery1 = User.find_or_create_by!(email: "carlos.mendoza@gmail.com") do |u|
  u.provider  = "google"
  u.uid       = "seed_delivery_001"
  u.name      = "Carlos Mendoza"
  u.role      = :delivery
  u.status    = :active
  u.api_token = SecureRandom.hex(32)
end

delivery2 = User.find_or_create_by!(email: "martin.perez@gmail.com") do |u|
  u.provider  = "google"
  u.uid       = "seed_delivery_002"
  u.name      = "Martín Pérez"
  u.role      = :delivery
  u.status    = :active
  u.api_token = SecureRandom.hex(32)
end

customer1 = User.find_or_create_by!(email: "ana.garcia@gmail.com") do |u|
  u.provider         = "google"
  u.uid              = "seed_customer_001"
  u.name             = "Ana García"
  u.role             = :customer
  u.status           = :active
  u.default_address  = "Ameghino 655, Dolores"
  u.api_token        = SecureRandom.hex(32)
end

customer2 = User.find_or_create_by!(email: "lucas.fernandez@gmail.com") do |u|
  u.provider         = "google"
  u.uid              = "seed_customer_002"
  u.name             = "Lucas Fernández"
  u.role             = :customer
  u.status           = :active
  u.default_address  = "Rivadavia 320, Dolores"
  u.api_token        = SecureRandom.hex(32)
end

customer3 = User.find_or_create_by!(email: "maria.gonzalez@gmail.com") do |u|
  u.provider  = "google"
  u.uid       = "seed_customer_003"
  u.name      = "María González"
  u.role      = :customer
  u.status    = :active
  u.api_token = SecureRandom.hex(32)
end

customer4 = User.find_or_create_by!(email: "pablo.torres@gmail.com") do |u|
  u.provider  = "google"
  u.uid       = "seed_customer_004"
  u.name      = "Pablo Torres"
  u.role      = :customer
  u.status    = :pending
  u.api_token = SecureRandom.hex(32)
end

# ── Órdenes ────────────────────────────────────────────────────────────────────

puts "Limpiando órdenes existentes..."
DeliveryLocation.delete_all
DeliveryAssignment.delete_all
OrderItem.delete_all
Order.delete_all

puts "Creando órdenes..."

# 1. Pendiente de pago — delivery / transferencia
order1 = create_order(
  user: customer1, modality: :delivery, payment_method: :transfer,
  delivery_address: "Ameghino 655, Dolores",
  total: 11_200,
  status: "pending_payment",
  created_at: 8.minutes.ago,
  items: [
    { menu_item: pollo_entero, quantity: 1, unit_price: pollo_entero.price },
    { menu_item: papas,        quantity: 1, unit_price: papas.price },
    { menu_item: coca,         quantity: 1, unit_price: coca.price }
  ]
)

# 2. Confirmada — delivery / efectivo
order2 = create_order(
  user: customer2, modality: :delivery, payment_method: :cash,
  delivery_address: "Rivadavia 320, Dolores",
  total: 9_000,
  status: "confirmed",
  created_at: 22.minutes.ago,
  items: [
    { menu_item: medio_pollo, quantity: 2, unit_price: medio_pollo.price }
  ]
)

# 3. En preparación — pickup / efectivo
order3 = create_order(
  user: customer3, modality: :pickup, payment_method: :cash,
  total: 8_500,
  status: "preparing",
  created_at: 38.minutes.ago,
  items: [
    { menu_item: pollo_entero, quantity: 1, unit_price: pollo_entero.price }
  ]
)

# 4. Lista — delivery / transferencia
order4 = create_order(
  user: customer1, modality: :delivery, payment_method: :transfer,
  delivery_address: "Ameghino 655, Dolores",
  total: 12_600,
  status: "ready",
  created_at: 52.minutes.ago,
  items: [
    { menu_item: pollo_entero, quantity: 1, unit_price: pollo_entero.price },
    { menu_item: ensalada,     quantity: 1, unit_price: ensalada.price },
    { menu_item: coca,         quantity: 2, unit_price: coca.price },
    { menu_item: papas,        quantity: 1, unit_price: papas.price }
  ]
)

# 5. En camino — con repartidor y GPS
order5 = create_order(
  user: customer2, modality: :delivery, payment_method: :cash,
  delivery_address: "Rivadavia 320, Dolores",
  total: 17_000,
  status: "delivering",
  created_at: 75.minutes.ago,
  items: [
    { menu_item: pollo_entero, quantity: 2, unit_price: pollo_entero.price }
  ]
)

assignment1 = DeliveryAssignment.create!(
  order: order5, user: delivery1,
  status: "in_transit",
  assigned_at: 45.minutes.ago,
  departed_at: 20.minutes.ago,
  created_at: 45.minutes.ago
)
DeliveryLocation.create!(
  delivery_assignment: assignment1,
  latitude: -36.3149, longitude: -57.6831,
  recorded_at: 3.minutes.ago
)

# 6. Entregada — con historial de assignment
order6 = create_order(
  user: customer3, modality: :delivery, payment_method: :transfer,
  delivery_address: "Belgrano 450, Dolores",
  total: 9_900,
  status: "delivered",
  created_at: 2.hours.ago,
  items: [
    { menu_item: medio_pollo, quantity: 2, unit_price: medio_pollo.price },
    { menu_item: coca,        quantity: 1, unit_price: coca.price }
  ]
)
assignment2 = DeliveryAssignment.create!(
  order: order6, user: delivery2,
  status: "delivered",
  assigned_at: 110.minutes.ago,
  departed_at: 100.minutes.ago,
  delivered_at: 80.minutes.ago,
  created_at: 110.minutes.ago
)
DeliveryLocation.create!(
  delivery_assignment: assignment2,
  latitude: -36.3185, longitude: -57.6820,
  recorded_at: 80.minutes.ago
)

# 7. Entregada 2 — por delivery1 también
order7 = create_order(
  user: customer1, modality: :delivery, payment_method: :cash,
  delivery_address: "Ameghino 655, Dolores",
  total: 4_500,
  status: "delivered",
  created_at: 3.hours.ago,
  items: [
    { menu_item: medio_pollo, quantity: 1, unit_price: medio_pollo.price }
  ]
)
assignment3 = DeliveryAssignment.create!(
  order: order7, user: delivery1,
  status: "delivered",
  assigned_at: 170.minutes.ago,
  departed_at: 160.minutes.ago,
  delivered_at: 145.minutes.ago,
  created_at: 170.minutes.ago
)

# 8. Cancelada
order8 = create_order(
  user: customer4, modality: :delivery, payment_method: :transfer,
  delivery_address: "Sarmiento 100, Dolores",
  total: 8_500,
  status: "cancelled",
  created_at: 3.5.hours.ago,
  cancelled_by: admin,
  cancelled_at: 3.hours.ago + 20.minutes,
  cancellation_reason: "El cliente no respondió al llamado",
  items: [
    { menu_item: pollo_entero, quantity: 1, unit_price: pollo_entero.price }
  ]
)

# 9. Pickup entregado — cliente 3, sin repartidor
order9 = create_order(
  user: customer3, modality: :pickup, payment_method: :cash,
  total: 6_300,
  status: "delivered",
  created_at: 4.hours.ago,
  items: [
    { menu_item: medio_pollo, quantity: 1, unit_price: medio_pollo.price },
    { menu_item: papas,       quantity: 1, unit_price: papas.price },
    { menu_item: agua,        quantity: 1, unit_price: agua.price }
  ]
)

# ── Actualizar stock ────────────────────────────────────────────────────────────
# 6 órdenes confirmadas o más (contamos los pollos usados)
stock.update!(used: 10)

# ── Resumen ────────────────────────────────────────────────────────────────────

puts ""
puts "Seeds completados!"
puts ""
puts "=== Usuarios creados ==="
puts "  Admin:        #{admin.name} (#{admin.email})"
puts "  Delivery 1:   #{delivery1.name} (#{delivery1.email})"
puts "  Delivery 2:   #{delivery2.name} (#{delivery2.email})"
puts "  Clientes:     #{customer1.name}, #{customer2.name}, #{customer3.name}, #{customer4.name} (pendiente)"
puts ""
puts "=== Órdenes ==="
puts "  pending_payment: 1 | confirmed: 1 | preparing: 1 | ready: 1"
puts "  delivering: 1 | delivered: 3 | cancelled: 1"
puts ""
puts "=== Tokens de acceso (solo dev) ==="
puts "  Admin:      #{admin.api_token}"
puts "  Delivery 1: #{delivery1.api_token}"
puts "  Delivery 2: #{delivery2.api_token}"
puts "  Cliente 1:  #{customer1.api_token}"
puts "  Cliente 2:  #{customer2.api_token}"
