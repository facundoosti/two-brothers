class ApplicationController < ActionController::API
  include Pagy::Method
  include Pundit::Authorization

  before_action :set_active_storage_url_options
  before_action :authenticate_user!

  after_action { response.headers.merge!(@pagy.headers_hash) if @pagy }

  rescue_from Pundit::NotAuthorizedError, with: :pundit_not_authorized

  private

  def pagy_meta(pagy)
    {
      page:  pagy.page,
      pages: pagy.pages,
      count: pagy.count,
      limit: pagy.limit,
      from:  pagy.from,
      to:    pagy.to,
      prev:  pagy.previous,
      next:  pagy.next
    }
  end

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    @current_user = User.find_by(api_token: token) if token
    render json: { error: I18n.t("errors.unauthorized") }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end

  def pundit_user
    current_user
  end

  def pundit_not_authorized
    render json: { error: I18n.t("errors.forbidden") }, status: :forbidden
  end

  def set_active_storage_url_options
    ActiveStorage::Current.url_options = { host: request.base_url }
  end

  def render_error(message, status: :unprocessable_entity)
    render json: { error: message }, status: status
  end
end
