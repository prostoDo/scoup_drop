require "test_helper"

module YouTrack
  class SyncServiceTest < ActiveSupport::TestCase
    FakeClient = Data.define(:sprint_payload, :issue_payloads) do
      def sprints = sprint_payload
      def issues_for(sprint) = issue_payloads.fetch(sprint.fetch("id"))
    end

    setup do
      SprintDailySnapshot.delete_all
      SprintIssue.delete_all
      Issue.delete_all
      Sprint.delete_all
    end

    test "captures inferred initial scope then tracks additions, removals, and returns" do
      now = Time.zone.parse("2026-06-10 12:00")
      client = fake_client(%w[SD-1 SD-2])
      run_sync(client, now)

      sprint = Sprint.find_by!(youtrack_id: "sprint")
      assert sprint.initial_scope_inferred?
      assert sprint.sprint_issues.all?(&:is_initial_scope?)

      run_sync(fake_client(%w[SD-1 SD-3]), now + 1.day)
      sprint.reload
      removed = sprint.sprint_issues.joins(:issue).find_by!(issues: { key: "SD-2" })
      added = sprint.sprint_issues.joins(:issue).find_by!(issues: { key: "SD-3" })
      assert removed.is_removed_from_sprint?
      assert_not removed.currently_in_sprint?
      assert added.is_added_after_start?

      run_sync(fake_client(%w[SD-1 SD-2 SD-3]), now + 2.days)
      removed.reload
      assert removed.currently_in_sprint?
      assert_not removed.is_removed_from_sprint?
      assert_nil removed.removed_from_sprint_at
      assert_equal 3, sprint.daily_snapshots.count
    end

    test "daily mode ignores inactive sprints" do
      now = Time.zone.parse("2026-07-10 12:00")
      run_sync(fake_client(%w[SD-1]), now, mode: :daily)

      assert Sprint.exists?(youtrack_id: "sprint")
      assert_equal 0, SprintIssue.count
      assert_equal 0, SprintDailySnapshot.count
    end

    test "marks a pre-start issue as added when it was absent from the baseline" do
      run_sync(fake_client(%w[SD-1]), Time.zone.parse("2026-05-30 12:00"))
      run_sync(fake_client([]), Time.zone.parse("2026-06-01 12:00"))
      run_sync(fake_client(%w[SD-1]), Time.zone.parse("2026-06-02 12:00"))

      association = SprintIssue.joins(:issue).find_by!(issues: { key: "SD-1" })
      assert_not association.is_initial_scope?
      assert association.is_added_after_start?
      assert association.currently_in_sprint?
    end

    test "rolls back database changes when applying a fetched payload fails" do
      client = fake_client(%w[SD-1])
      invalid = client.issue_payloads["sprint"].first.merge(summary: nil)
      failing_client = FakeClient.new(client.sprint_payload, { "sprint" => [ invalid ] })

      assert_raises(ActiveRecord::RecordInvalid) do
        run_sync(failing_client, Time.zone.parse("2026-06-10 12:00"))
      end

      assert_equal 0, Sprint.count
      assert_equal 0, Issue.count
    end

    test "rejects a concurrent synchronization when the advisory lock is busy" do
      connection = Object.new
      connection.define_singleton_method(:quote) { |value| "'#{value}'" }
      connection.define_singleton_method(:select_value) { |_sql| false }

      with_stubbed_method(ActiveRecord::Base, :connection, connection) do
        assert_raises(SyncInProgress) do
          SyncService.new(client: fake_client(%w[SD-1])).call
        end
      end
    end

    private

    def run_sync(client, now, mode: :manual)
      SyncService.new(mode: mode, client: client, now: now).call
    end

    def fake_client(keys)
      sprint = {
        "id" => "sprint",
        "name" => "Sprint",
        "start" => Time.zone.parse("2026-06-01").to_i * 1000,
        "finish" => Time.zone.parse("2026-06-30").to_i * 1000,
        "archived" => false
      }
      issues = keys.map.with_index do |key, index|
        {
          youtrack_id: "issue-#{key}",
          key: key,
          summary: "Task #{key}",
          url: "https://youtrack.example/issue/#{key}",
          assignee_name: "Developer",
          status: "Open",
          estimation_be: BigDecimal((index + 1).to_s)
        }
      end
      FakeClient.new([ sprint ], { "sprint" => issues })
    end
  end
end
