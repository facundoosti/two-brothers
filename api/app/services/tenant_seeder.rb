# Inicializa un schema de tenant recién creado con la configuración base
# necesaria para que la plataforma funcione.
#
# Uso:
#   TenantSeeder.call("tastychicken", name: "Tasty Chicken")
#
class TenantSeeder
  def self.call(subdomain, name:)
    Apartment::Tenant.switch(subdomain) do
      seed_settings(name)
      seed_categories
      seed_dev_users if Rails.env.development?
    end
    Rails.logger.info("TenantSeeder: tenant '#{subdomain}' inicializado.")
  end

  def self.seed_settings(store_name)
    {
      "store_name"    => store_name,
      "store_address" => "Configurar dirección",
      "open_days"     => "4,5,6,0",
      "opening_time"  => "20:00",
      "closing_time"  => "00:00",
      "mp_alias"      => "configurar.mp"
    }.each { |k, v| Setting[k] = v }
  end

  def self.seed_categories
    Category.find_or_create_by!(name: "Principal")   { |c| c.position = 1 }
    Category.find_or_create_by!(name: "Adicionales") { |c| c.position = 2 }
    Category.find_or_create_by!(name: "Bebidas")     { |c| c.position = 3 }
  end

  def self.seed_dev_users
    admin = User.find_or_create_by!(uid: "seed_admin_001") do |u|
      u.email     = "facundo@twobrothers.com"
      u.provider  = "google"
      u.name      = "Facundo Osti"
      u.role      = :admin
      u.status    = :active
      u.api_token = SecureRandom.hex(32)
    end
    admin.update!(role: :admin, status: :active)

    User.find_or_create_by!(uid: "seed_delivery_001") do |u|
      u.email     = "carlos.mendoza@gmail.com"
      u.provider  = "google"
      u.name      = "Carlos Mendoza"
      u.role      = :delivery
      u.status    = :active
      u.api_token = SecureRandom.hex(32)
    end

    User.find_or_create_by!(uid: "seed_customer_002") do |u|
      u.email     = "lucas.fernandez@gmail.com"
      u.provider  = "google"
      u.name      = "Lucas Fernández"
      u.role      = :customer
      u.status    = :active
      u.api_token = SecureRandom.hex(32)
    end
  end
end
