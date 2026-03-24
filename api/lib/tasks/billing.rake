namespace :billing do
  desc "Generate billing periods for a specific month. Usage: rake billing:generate[2026,3]"
  task :generate, %i[year month] => :environment do |_t, args|
    year  = args[:year].to_i
    month = args[:month].to_i

    abort "Usage: rake billing:generate[YEAR,MONTH]" unless year.positive? && month.between?(1, 12)

    unless ExchangeRate.for(Date.new(year, month, 1))
      abort "[Billing] Sin cotización blue para #{year}/#{month}. Registrala antes de generar períodos."
    end

    generated = 0
    skipped   = 0
    errors    = []

    Subscription.active.each do |subscription|
      BillingPeriod.generate_for(subscription, year, month)
      generated += 1
      puts "[OK] #{subscription.tenant.name} — #{month}/#{year}"
    rescue ActiveRecord::RecordNotUnique
      skipped += 1
      puts "[SKIP] #{subscription.tenant.name} — ya existe un período para #{month}/#{year}"
    rescue => e
      errors << subscription.tenant.name
      puts "[ERROR] #{subscription.tenant.name}: #{e.message}"
    end

    puts "\nResumen: #{generated} generados, #{skipped} saltados, #{errors.size} errores."
    puts "Errores en: #{errors.join(', ')}" if errors.any?
  end
end
