class Superadmin::SubscriptionsController < Superadmin::BaseController
  before_action :set_subscription, only: %i[suspend reactivate]

  def index
    @subscriptions = Subscription.includes(:tenant).order("tenants.name")
  end

  def create
    @subscriptions = Subscription.includes(:tenant).order("tenants.name")
    @subscription  = Subscription.new(subscription_params)

    if @subscription.save
      redirect_to superadmin_subscriptions_path,
                  notice: "Suscripción creada para #{@subscription.tenant.name}."
    else
      render :index, status: :unprocessable_entity
    end
  end

  def suspend
    if @subscription.suspended?
      redirect_to superadmin_subscriptions_path, alert: "La suscripción ya estaba suspendida."
    else
      @subscription.update!(status: :suspended)
      redirect_to superadmin_subscriptions_path,
                  notice: "Suscripción de #{@subscription.tenant.name} suspendida."
    end
  end

  def reactivate
    if @subscription.active?
      redirect_to superadmin_subscriptions_path, alert: "La suscripción ya estaba activa."
    else
      @subscription.update!(status: :active)
      redirect_to superadmin_subscriptions_path,
                  notice: "Suscripción de #{@subscription.tenant.name} reactivada."
    end
  end

  private

  def set_subscription
    @subscription = Subscription.find(params[:id])
  end

  def subscription_params
    params.require(:subscription).permit(:tenant_id, :started_at)
  end
end
