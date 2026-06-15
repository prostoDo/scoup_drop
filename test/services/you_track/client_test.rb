require "test_helper"

module YouTrack
  class ClientTest < ActiveSupport::TestCase
    class StubClient < Client
      attr_reader :requests

      def initialize(responses)
        super(
          base_url: "https://youtrack.example",
          token: "token",
          project_id: "SD",
          board_id: "board",
          sprint_field_name: "Sprint",
          estimation_field_name: "оценка BE"
        )
        @responses = responses
        @requests = []
      end

      private

      def get(path, params)
        @requests << [ path, params ]
        @responses.shift
      end
    end

    test "paginates collection requests" do
      full_page = Array.new(100) { |index| { "id" => index.to_s, "name" => "Sprint #{index}" } }
      client = StubClient.new([ full_page, [] ])

      assert_equal 100, client.sprints.length
      assert_equal [ 0, 100 ], client.requests.map { |(_, params)| params[:"$skip"] }
    end

    test "normalizes issue custom fields" do
      raw = {
        "id" => "2-1",
        "idReadable" => "SD-1",
        "summary" => "Task",
        "customFields" => [
          { "name" => "Assignee", "$type" => "SingleUserIssueCustomField", "value" => { "name" => "Ivan" } },
          { "name" => "State", "$type" => "StateIssueCustomField", "value" => { "name" => "Done" } },
          { "name" => "оценка BE", "$type" => "SimpleIssueCustomField", "value" => 3.5 }
        ]
      }
      client = StubClient.new([ [ raw ] ])

      issue = client.issues_for("name" => "Sprint 1").first

      assert_equal "Ivan", issue[:assignee_name]
      assert_equal "Done", issue[:status]
      assert_equal BigDecimal("3.5"), issue[:estimation_be]
      assert_equal "https://youtrack.example/issue/SD-1", issue[:url]
    end
  end
end
