class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :email, :avatar_url, :role, :status, :default_address, :created_at

  view :minimal do
    fields :name, :email
  end
end
