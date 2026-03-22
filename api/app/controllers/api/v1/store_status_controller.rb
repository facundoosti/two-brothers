module Api
  module V1
    class StoreStatusController < BaseController
      skip_before_action :authenticate_user!

      # GET /api/v1/store_status — público, sin auth
      def show
        render json: {
          open:                 StoreSchedule.open?,
          stock_available:      DailyStock.today.available,
          opening_time:         Setting["opening_time"] || "20:00",
          closing_time:         Setting["closing_time"] || "00:00",
          open_days:            (Setting["open_days"] || "4,5,6,0").split(",").map(&:to_i),
          delivery_fee:         (Setting["delivery_fee"] || "0").to_f,
          delivery_fee_enabled: Setting["delivery_fee_enabled"] == "true"
        }
      end
    end
  end
end
