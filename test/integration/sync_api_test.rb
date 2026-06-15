require "test_helper"

class SyncApiTest < ActionDispatch::IntegrationTest
  FakeService = Data.define(:result) do
    def call
      raise result if result.is_a?(Exception)

      result
    end
  end

  setup do
    ENV["APP_LOGIN"] = "admin"
    ENV["APP_PASSWORD"] = "secret"
    @csrf = login
  end

  test "starts a manual synchronization" do
    with_stubbed_method(YouTrack::SyncService, :new, FakeService.new(true)) do
      post "/api/sync", headers: json_headers
    end

    assert_response :success
    assert_equal "success", response.parsed_body["status"]
  end

  test "returns conflict when synchronization is already running" do
    service = FakeService.new(YouTrack::SyncInProgress.new)
    with_stubbed_method(YouTrack::SyncService, :new, service) do
      post "/api/sync", headers: json_headers
    end

    assert_response :conflict
    assert_equal "sync_in_progress", response.parsed_body["error"]
  end

  test "returns bad gateway for a YouTrack failure" do
    service = FakeService.new(YouTrack::Error.new("unavailable"))
    with_stubbed_method(YouTrack::SyncService, :new, service) do
      post "/api/sync", headers: json_headers
    end

    assert_response :bad_gateway
    assert_equal "youtrack_sync_failed", response.parsed_body["error"]
  end

  private

  def login
    get "/api/auth/me"
    token = response.parsed_body.fetch("csrf_token")
    post "/api/auth/login",
      params: { login: "admin", password: "secret" }.to_json,
      headers: { "CONTENT_TYPE" => "application/json", "X-CSRF-Token" => token }
    get "/api/auth/me"
    response.parsed_body.fetch("csrf_token")
  end

  def json_headers
    { "CONTENT_TYPE" => "application/json", "X-CSRF-Token" => @csrf }
  end
end
