module Api
  module V1
    class BillingController < BaseController
      before_action :ensure_admin!

      def show
        subscription = current_tenant_subscription

        unless subscription
          render json: { error: I18n.t("errors.billing.no_subscription") }, status: :not_found
          return
        end

        today        = Date.today
        current_rate = ExchangeRate.for(today)

        # Ventas delivered del mes en curso (estimado parcial)
        estimated_sales = fetch_delivered_sales_for_current_month

        current_plan_key     = subscription.current_plan
        usd_base             = current_plan_key == :adopcion ? 25.0 : 20.0
        variable_pct         = case current_plan_key
                               when :penetracion then 0.0
                               when :puente      then 0.003
                               when :adopcion    then 0.005
                               end
        blue_rate_value      = current_rate&.blue_rate || 0
        base_ars             = usd_base * blue_rate_value
        estimated_variable   = estimated_sales * variable_pct
        estimated_total      = base_ars + estimated_variable

        next_due = Date.new(today.year, today.month, 1).next_month + 4

        history = subscription.billing_periods
                               .order(year: :desc, month: :desc)
                               .limit(12)

        render json: {
          subscription: {
            id:                    subscription.id,
            started_at:            subscription.started_at,
            status:                subscription.status,
            current_billing_month: subscription.current_billing_month,
            current_plan:          subscription.current_plan
          },
          current_month: {
            plan:               current_plan_key,
            usd_base:           usd_base.to_f,
            blue_rate:          blue_rate_value.to_f,
            base_ars:           base_ars.to_f.round(2),
            variable_pct:       variable_pct.to_f,
            estimated_sales:    estimated_sales.to_f.round(2),
            estimated_variable: estimated_variable.to_f.round(2),
            estimated_total:    estimated_total.to_f.round(2),
            next_due_date:      next_due
          },
          history: history.map { |bp| billing_period_summary(bp) }
        }
      end

      private

      def ensure_admin!
        render json: { error: I18n.t("errors.forbidden") }, status: :forbidden unless current_user.admin?
      end

      def current_tenant_subscription
        tenant = Tenant.find_by(subdomain: request.subdomain)
        tenant&.subscriptions&.active&.first
      end

      def fetch_delivered_sales_for_current_month
        today = Date.today
        Order
          .where(status: "delivered")
          .where(
            updated_at: Date.new(today.year, today.month, 1).beginning_of_day..
                        today.end_of_day
          )
          .sum(:total)
      end

      def billing_period_summary(bp)
        {
          id:                   bp.id,
          year:                 bp.year,
          month:                bp.month,
          billing_month_number: bp.billing_month_number,
          plan:                 bp.plan,
          base_ars:             bp.base_ars.to_f,
          delivered_sales_ars:  bp.delivered_sales_ars.to_f,
          variable_ars:         bp.variable_ars.to_f,
          total_ars:            bp.total_ars.to_f,
          status:               bp.status,
          due_date:             bp.due_date
        }
      end
    end
  end
end
