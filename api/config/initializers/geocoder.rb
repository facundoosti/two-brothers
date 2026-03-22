Geocoder.configure(
  # Nominatim (OpenStreetMap) — sin API key, compatible con los tiles del mapa
  lookup: :nominatim,

  # Nominatim requiere un User-Agent con contacto (política de uso)
  http_headers: { "User-Agent" => "TwoBrothers/1.0 (#{ENV.fetch('CONTACT_EMAIL', 'admin@twobrothers.com')})" },

  # Timeout en segundos
  timeout: 5,

  # Cache para no repetir geocodeos del mismo string (usa la cache de Rails)
  cache: Rails.cache,
  cache_options: { expiration: 1.week, prefix: "geocoder:" },

  units: :km
)

# Coordenadas del local — origen de todos los deliveries.
# Usadas por el frontend para dibujar la ruta origen→destino en el mapa.
STORE_COORDINATES = {
  address:   ENV.fetch("STORE_ADDRESS",   "Washington 133, Dolores, Buenos Aires, Argentina"),
  latitude:  ENV.fetch("STORE_LATITUDE",  "-36.3133").to_f,
  longitude: ENV.fetch("STORE_LONGITUDE", "-57.6837").to_f
}.freeze
