require "test_helper"

class SprintsApiTest < ActionDispatch::IntegrationTest
  setup do
    ENV["APP_LOGIN"] = "admin"
    ENV["APP_PASSWORD"] = "secret"
  end

  test "protects sprint endpoints" do
    get "/api/sprints"
    assert_response :unauthorized
  end

  test "returns sprint summaries and details as numeric JSON values" do
    login

    get "/api/sprints"
    assert_response :success
    item = response.parsed_body.fetch("items").first
    assert_equal "Sprint 1", item["name"]
    assert_equal 8.5, item["planned_sp"]

    get "/api/sprints/#{sprints(:current).id}"
    assert_response :success
    body = response.parsed_body
    assert_equal false, body.dig("sprint", "initial_scope_inferred")
    assert_equal 4, body.fetch("issues").length
    assert_equal 3, body.fetch("developers").length
  end

  test "returns not found for a missing sprint" do
    login
    get "/api/sprints/999999"
    assert_response :not_found
  end

  private

  def login
    get "/api/auth/me"
    csrf = response.parsed_body.fetch("csrf_token")
    post "/api/auth/login",
      params: { login: "admin", password: "secret" }.to_json,
      headers: { "CONTENT_TYPE" => "application/json", "X-CSRF-Token" => csrf }
  end
end
