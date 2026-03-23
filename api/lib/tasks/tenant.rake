namespace :tenant do
  desc "Crear nuevo tenant: rake tenant:create[nombre,subdominio]"
  task :create, [ :name, :subdomain ] => :environment do |_, args|
    abort "Uso: rake tenant:create[nombre,subdominio]" unless args[:name] && args[:subdomain]

    tenant = Tenant.create!(name: args[:name], subdomain: args[:subdomain])
    Apartment::Tenant.create(tenant.subdomain)
    TenantSeeder.call(tenant.subdomain, name: tenant.name)
    puts "✅ Tenant '#{tenant.subdomain}' (#{tenant.name}) creado correctamente."
  end

  desc "Eliminar tenant: rake tenant:drop[subdominio]"
  task :drop, [ :subdomain ] => :environment do |_, args|
    abort "Uso: rake tenant:drop[subdominio]" unless args[:subdomain]

    tenant = Tenant.find_by!(subdomain: args[:subdomain])
    Apartment::Tenant.drop(tenant.subdomain)
    tenant.destroy!
    puts "🗑️  Tenant '#{args[:subdomain]}' eliminado."
  end

  desc "Listar todos los tenants"
  task list: :environment do
    tenants = Tenant.order(:subdomain)

    if tenants.empty?
      puts "No hay tenants registrados."
    else
      puts "%-20s %-30s %-8s %s" % [ "Subdominio", "Nombre", "Activo", "Creado" ]
      puts "-" * 72
      tenants.each do |t|
        puts "%-20s %-30s %-8s %s" % [ t.subdomain, t.name, t.active ? "sí" : "no", t.created_at.strftime("%Y-%m-%d") ]
      end
    end
  end

  desc "Migrar todos los tenants existentes"
  task migrate: :environment do
    Tenant.pluck(:subdomain).each do |subdomain|
      puts "→ Migrando schema '#{subdomain}'..."
      Apartment::Tenant.switch(subdomain) do
        ActiveRecord::MigrationContext.new(
          ActiveRecord::Migrator.migrations_paths
        ).migrate
      end
    end
    puts "✅ Todos los tenants migrados."
  end
end
