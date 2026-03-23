require "apartment/elevators/subdomain"

# Resuelve el tenant activo a partir del subdominio de cada request.
#
# Flujo:
#   tastychicken.two-brothers.shop  → activa schema "tastychicken"
#   admin.two-brothers.shop         → sin schema (opera en public, panel superadmin)
#   two-brothers.shop               → sin schema (opera en public, landing page)
#   localhost / 127.0.0.1           → usa DEFAULT_TENANT en development, sin schema en otros entornos
#
# Errores:
#   Subdominio sin tenant activo en la DB → 404 JSON
#
class TenantResolver < Apartment::Elevators::Subdomain
  RESERVED_SUBDOMAINS = %w[www api admin].freeze

  def call(env)
    request = Rack::Request.new(env)
    subdomain = parse_tenant_name(request)

    # Fallback de desarrollo: DEFAULT_TENANT env var cuando no hay subdomain real
    subdomain ||= ENV["DEFAULT_TENANT"] if Rails.env.development?

    if subdomain.present?
      tenant = Tenant.find_by(subdomain: subdomain, active: true)

      unless tenant
        return [
          404,
          { "Content-Type" => "application/json" },
          [{ error: I18n.t("errors.tenant_not_found") }.to_json]
        ]
      end

      Apartment::Tenant.switch(subdomain) { @app.call(env) }
    else
      @app.call(env)
    end
  rescue Apartment::TenantNotFound
    [
      404,
      { "Content-Type" => "application/json" },
      [{ error: I18n.t("errors.tenant_not_found") }.to_json]
    ]
  end

  private

  def parse_tenant_name(request)
    subdomain = super
    return nil if RESERVED_SUBDOMAINS.include?(subdomain)

    subdomain
  end
end
