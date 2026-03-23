Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins lambda { |source, _env|
      allowed_origins = [
        # Producción: cualquier subdominio de two-brothers.shop
        /\Ahttps?:\/\/([a-z0-9\-]+\.)?two-brothers\.shop(:\d+)?\z/,
        # Desarrollo: cualquier subdominio de lvh.me
        /\Ahttps?:\/\/([a-z0-9\-]+\.)?lvh\.me(:\d+)?\z/,
        # Fallback local sin subdominio
        /\Ahttps?:\/\/localhost(:\d+)?\z/
      ]

      allowed_origins.any? { |pattern| source.match?(pattern) }
    }

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      expose: [ "Authorization" ],
      credentials: false
  end
end
