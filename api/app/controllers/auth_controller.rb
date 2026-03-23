class AuthController < ApplicationController
  skip_before_action :authenticate_user!

  # GET /auth/google?tenant=empresa
  # Inicia el flujo OAuth almacenando el tenant en session y redirigiendo a Google.
  # Debe accederse desde el dominio raíz (sin subdominio) para que la cookie de session
  # sea compartida con el callback.
  def new_oauth
    session[:oauth_tenant] = params[:tenant].presence
    session[:oauth_state]  = SecureRandom.hex(16)

    redirect_to google_auth_url(session[:oauth_state]), allow_other_host: true
  end

  # GET /auth/google/callback
  # Google redirige aquí con ?code=xxx&state=yyy tras la autenticación.
  # Intercambia el code por un access_token, obtiene el perfil del usuario,
  # lo busca/crea en el schema del tenant y redirige al frontend con el token.
  def callback
    tenant = session.delete(:oauth_tenant)
    state  = session.delete(:oauth_state)

    if params[:error].present? || params[:state] != state
      return redirect_to frontend_error_url("oauth_failed", tenant:), allow_other_host: true
    end

    payload = exchange_code(params[:code])
    unless payload
      return redirect_to frontend_error_url("oauth_failed", tenant:), allow_other_host: true
    end

    user = in_tenant(tenant) { User.from_google(payload) }

    if user.active?
      redirect_to frontend_callback_url(user.api_token, tenant:), allow_other_host: true
    else
      redirect_to frontend_error_url("pending", tenant:), allow_other_host: true
    end
  rescue => e
    Rails.logger.error("OAuth callback error: #{e.message}")
    redirect_to frontend_error_url("oauth_failed", tenant: session.delete(:oauth_tenant)),
                allow_other_host: true
  end

  private

  # Construye la URL de autorización de Google con los scopes mínimos necesarios.
  def google_auth_url(state)
    query = {
      client_id:     ENV.fetch("GOOGLE_CLIENT_ID"),
      redirect_uri:  google_redirect_uri,
      response_type: "code",
      scope:         "openid email profile",
      state:         state
    }.to_query
    "https://accounts.google.com/o/oauth2/v2/auth?#{query}"
  end

  # Intercambia el authorization code por el perfil del usuario.
  # Retorna el hash de userinfo o nil si falla.
  def exchange_code(code)
    token_res = HTTParty.post(
      "https://oauth2.googleapis.com/token",
      body: {
        code:          code,
        client_id:     ENV.fetch("GOOGLE_CLIENT_ID"),
        client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
        redirect_uri:  google_redirect_uri,
        grant_type:    "authorization_code"
      }
    )
    return nil unless token_res.success?

    access_token = token_res.parsed_response["access_token"]

    userinfo_res = HTTParty.get(
      "https://www.googleapis.com/oauth2/v3/userinfo",
      headers: { "Authorization" => "Bearer #{access_token}" }
    )
    userinfo_res.success? ? userinfo_res.parsed_response : nil
  rescue => e
    Rails.logger.error("Google token exchange failed: #{e.message}")
    nil
  end

  # URL de callback registrada en Google Cloud Console.
  # Producción: BASE_URL=https://two-brothers.shop
  # Desarrollo:  BASE_URL=http://lvh.me:3000
  def google_redirect_uri
    "#{ENV.fetch('BASE_URL', 'http://lvh.me:3000')}/auth/google/callback"
  end

  # Ejecuta el bloque dentro del schema del tenant.
  # Si no hay tenant, opera en el schema public.
  def in_tenant(tenant, &block)
    tenant.present? ? Apartment::Tenant.switch(tenant, &block) : yield
  end

  # URL base del frontend para el tenant dado.
  # FRONTEND_URL=http://lvh.me:5173 + tenant=empresa → http://empresa.lvh.me:5173
  def frontend_base_url(tenant)
    base = ENV.fetch("FRONTEND_URL", "http://localhost:5173")
    return base unless tenant.present?

    uri      = URI.parse(base)
    uri.host = "#{tenant}.#{uri.host}"
    uri.to_s
  end

  def frontend_callback_url(token, tenant: nil)
    "#{frontend_base_url(tenant)}/auth/callback?token=#{token}"
  end

  def frontend_error_url(error, tenant: nil)
    "#{frontend_base_url(tenant)}/login?error=#{error}"
  end
end
