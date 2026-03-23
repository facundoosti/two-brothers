module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!

      # POST /api/v1/auth/google
      # Verifica un access_token de Google obtenido por el cliente y devuelve un token de sesión.
      def google
        google_response = HTTParty.get(
          "https://www.googleapis.com/oauth2/v3/userinfo",
          headers: { "Authorization" => "Bearer #{params[:access_token]}" }
        )

        unless google_response.success?
          return render json: { error: I18n.t("errors.oauth_failed") }, status: :unauthorized
        end

        user = User.from_google(google_response.parsed_response)

        if user.active?
          render json: { token: user.api_token, user: UserBlueprint.render_as_hash(user) }
        else
          render json: { error: I18n.t("errors.account_pending") }, status: :forbidden
        end
      rescue => e
        Rails.logger.error("Google token verification failed: #{e.message}")
        render json: { error: I18n.t("errors.oauth_failed") }, status: :unauthorized
      end
    end
  end
end
