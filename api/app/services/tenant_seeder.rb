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
      seed_daily_stock
    end
    Rails.logger.info("TenantSeeder: tenant '#{subdomain}' inicializado.")
  end

  def self.seed_settings(store_name)
    {
      "store_name"          => store_name,
      "store_address"       => "Configurar dirección",
      "daily_chicken_stock" => "100",
      "open_days"           => "4,5,6,0",
      "opening_time"        => "20:00",
      "closing_time"        => "00:00",
      "mp_alias"            => "configurar.mp"
    }.each { |k, v| Setting[k] = v }
  end

  def self.seed_categories
    Category.find_or_create_by!(name: "Principal")   { |c| c.position = 1 }
    Category.find_or_create_by!(name: "Adicionales") { |c| c.position = 2 }
    Category.find_or_create_by!(name: "Bebidas")     { |c| c.position = 3 }
  end

  def self.seed_daily_stock
    DailyStock.find_or_create_by!(date: Date.today) { |s| s.total = 100; s.used = 0 }
  end
end
