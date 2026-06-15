class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection

  protect_from_forgery with: :exception

  rescue_from ActionController::InvalidAuthenticityToken do
    render json: { error: "invalid_csrf_token" }, status: :unprocessable_entity
  end

  private

  def authenticated?
    session[:authenticated] == true
  end

  def require_authenticated!
    return if authenticated?

    render json: { error: "unauthorized" }, status: :unauthorized
  end
end
