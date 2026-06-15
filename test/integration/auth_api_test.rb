require "test_helper"

class AuthApiTest < ActionDispatch::IntegrationTest
  setup do
    @original_login = ENV["APP_LOGIN"]
    @original_password = ENV["APP_PASSWORD"]
    ENV["APP_LOGIN"] = "admin"
    ENV["APP_PASSWORD"] = "secret"
  end

  teardown do
    ENV["APP_LOGIN"] = @original_login
    ENV["APP_PASSWORD"] = @original_password
  end

  test "returns session state and csrf token" do
    get "/api/auth/me"

    assert_response :success
    assert_equal false, response.parsed_body["authenticated"]
    assert response.parsed_body["csrf_token"].present?
  end

  test "logs in, exposes authenticated state, and logs out" do
    csrf = csrf_token
    post "/api/auth/login",
      params: { login: "admin", password: "secret" }.to_json,
      headers: json_headers(csrf)

    assert_response :success
    assert_equal true, response.parsed_body["success"]

    get "/api/auth/me"
    assert_equal true, response.parsed_body["authenticated"]

    post "/api/auth/logout", headers: json_headers(response.parsed_body["csrf_token"])
    assert_response :success
  end

  test "rejects invalid credentials and missing csrf token" do
    post "/api/auth/login",
      params: { login: "admin", password: "wrong" }.to_json,
      headers: json_headers(csrf_token)
    assert_response :unauthorized

    post "/api/auth/login",
      params: { login: "admin", password: "secret" }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :unprocessable_entity
  end

  private

  def csrf_token
    get "/api/auth/me"
    response.parsed_body.fetch("csrf_token")
  end

  def json_headers(csrf)
    { "CONTENT_TYPE" => "application/json", "X-CSRF-Token" => csrf }
  end
end
