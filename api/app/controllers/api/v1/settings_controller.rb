module Api
  module V1
    class SettingsController < BaseController
      ALLOWED_KEYS = %w[
        mp_alias store_address store_name
        open_days opening_time closing_time
        delivery_fee delivery_fee_enabled
      ].freeze

      # GET /api/v1/settings
      def show
        authorize :setting, :show?
        settings = Setting.where(key: ALLOWED_KEYS).index_by(&:key)
        render json: ALLOWED_KEYS.map { { key: _1, value: settings[_1]&.value } }
      end

      # PATCH /api/v1/settings
      def update
        authorize :setting, :update?
        params.require(:settings).each do |key, value|
          next unless ALLOWED_KEYS.include?(key)
          next if value.blank?
          Setting[key] = value
        end
        head :no_content
      end
    end
  end
end
