class Superadmin::BaseController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_superadmin!

  layout "superadmin"
  helper :all
  helper Rails.application.routes.url_helpers

  private

  def authenticate_superadmin!
    authenticate_or_request_with_http_basic("Two Brothers · Superadmin") do |username, password|
      expected_user = ENV["SUPERADMIN_USERNAME"].presence
      expected_pass = ENV["SUPERADMIN_PASSWORD"].presence

      return false unless expected_user && expected_pass

      ActiveSupport::SecurityUtils.secure_compare(username, expected_user) &
        ActiveSupport::SecurityUtils.secure_compare(password, expected_pass)
    end
  end
end
