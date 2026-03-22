class DeliveryLocationBlueprint < Blueprinter::Base
  identifier :id

  fields :delivery_assignment_id, :latitude, :longitude, :recorded_at
end
