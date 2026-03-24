Apartment.configure do |config|
  # Tablas que viven en el schema public y NO se replican por tenant
  config.excluded_models = %w[Tenant Subscription ExchangeRate BillingPeriod]

  # Obtener lista de tenants para migraciones masivas
  config.tenant_names = lambda { Tenant.pluck(:subdomain) }

  # Usar schemas de PostgreSQL (un schema por tenant)
  config.use_schemas = true
end
