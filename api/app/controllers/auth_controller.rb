class AuthController < ApplicationController
  skip_before_action :authenticate_user!

  # POST /api/v1/auth/google
  def google
    access_token = params[:access_token]
    payload = verify_google_token(access_token)

    unless payload
      return render json: { error: I18n.t("errors.oauth_failed") }, status: :unauthorized
    end

    user = User.from_google(payload)

    if user.active?
      render json: { token: user.api_token, user: UserBlueprint.render_as_hash(user) }
    else
      render json: { error: I18n.t("errors.account_pending") }, status: :forbidden
    end
  rescue => e
    Rails.logger.error("OAuth error: #{e.message}")
    render json: { error: I18n.t("errors.oauth_failed") }, status: :unauthorized
  end

  private

  def verify_google_token(access_token)
    response = HTTParty.get(
      "https://www.googleapis.com/oauth2/v3/userinfo",
      headers: { "Authorization" => "Bearer #{access_token}" }
    )
    return nil unless response.success?

    response.parsed_response
  rescue => e
    Rails.logger.error("Google token verification failed: #{e.message}")
    nil
  end
end
