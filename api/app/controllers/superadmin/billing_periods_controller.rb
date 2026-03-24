class Superadmin::BillingPeriodsController < Superadmin::BaseController
  before_action :set_billing_period,             only: %i[mark_paid]
  before_action :set_billing_period_with_tenant, only: %i[show]

  def index
    @billing_periods = BillingPeriod
      .includes(subscription: :tenant)
      .order(year: :desc, month: :desc, created_at: :desc)

    @billing_periods = @billing_periods.where(subscriptions: { tenant_id: params[:tenant_id] })
                         .joins(:subscription) if params[:tenant_id].present?
    @billing_periods = @billing_periods.where(year: params[:year])   if params[:year].present?
    @billing_periods = @billing_periods.where(month: params[:month]) if params[:month].present?
    @billing_periods = @billing_periods.where(status: params[:status]) if params[:status].present?

    @tenants = Tenant.order(:name)
  end

  def show; end

  def mark_paid
    if @billing_period.paid?
      redirect_to superadmin_billing_period_path(@billing_period),
                  alert: "Este período ya estaba marcado como pagado."
    else
      @billing_period.update!(status: :paid)
      redirect_to superadmin_billing_period_path(@billing_period),
                  notice: "Período marcado como pagado."
    end
  end

  def generate
    year  = params[:year].to_i
    month = params[:month].to_i

    unless year.between?(2020, 2100) && month.between?(1, 12)
      redirect_to superadmin_billing_periods_path, alert: "Año o mes inválido."
      return
    end

    generated = 0
    errors    = []

    Subscription.active.each do |subscription|
      BillingPeriod.generate_for(subscription, year, month)
      generated += 1
    rescue ActiveRecord::RecordNotUnique
      errors << "#{subscription.tenant.name}: ya existe un período para #{month}/#{year}."
    rescue => e
      errors << "#{subscription.tenant.name}: #{e.message}"
    end

    notice = "#{generated} período(s) generado(s) para #{month}/#{year}."
    notice += " Errores: #{errors.join(' | ')}" if errors.any?
    redirect_to superadmin_billing_periods_path, notice: notice
  end

  private

  def set_billing_period
    @billing_period = BillingPeriod.find(params[:id])
  end

  def set_billing_period_with_tenant
    @billing_period = BillingPeriod.includes(subscription: :tenant).find(params[:id])
  end
end
