require "digest"

module Api
  class AuthController < ApplicationController
    before_action :require_authenticated!, only: :logout

    def login
      if valid_credentials?
        reset_session
        session[:authenticated] = true
        render json: { success: true }
      else
        render json: { success: false, error: "invalid_credentials" }, status: :unauthorized
      end
    end

    def logout
      reset_session
      render json: { success: true }
    end

    def me
      render json: {
        authenticated: authenticated?,
        csrf_token: form_authenticity_token
      }
    end

    private

    def valid_credentials?
      secure_equal(params[:login].to_s, ENV.fetch("APP_LOGIN", "")) &&
        secure_equal(params[:password].to_s, ENV.fetch("APP_PASSWORD", ""))
    end

    def secure_equal(candidate, expected)
      return false if expected.blank?

      ActiveSupport::SecurityUtils.secure_compare(
        Digest::SHA256.hexdigest(candidate),
        Digest::SHA256.hexdigest(expected)
      )
    end
  end
end
