Geocoder.configure(lookup: :test)

# Default stub: Dolores, Buenos Aires, Argentina
Geocoder::Lookup::Test.set_default_stub(
  [
    {
      "coordinates" => [ -36.3138, -57.6824 ],
      "address" => "Dolores, Buenos Aires, Argentina",
      "city" => "Dolores",
      "state" => "Buenos Aires",
      "country" => "Argentina",
      "country_code" => "AR"
    }
  ]
)

# Origen — local del negocio
Geocoder::Lookup::Test.add_stub(
  "Washington 133, Dolores, Buenos Aires, Argentina",
  [
    {
      "coordinates" => [ -36.3133, -57.6837 ],
      "address" => "Washington 133, Dolores, Buenos Aires, Argentina",
      "city" => "Dolores",
      "state" => "Buenos Aires",
      "country" => "Argentina",
      "country_code" => "AR"
    }
  ]
)

# Dirección de entrega usada en el factory :delivery
Geocoder::Lookup::Test.add_stub(
  "Av. Corrientes 1234, Dolores",
  [
    {
      "coordinates" => [ -36.3160, -57.6800 ],
      "address" => "Av. Corrientes 1234, Dolores, Buenos Aires, Argentina",
      "city" => "Dolores",
      "state" => "Buenos Aires",
      "country" => "Argentina",
      "country_code" => "AR"
    }
  ]
)
