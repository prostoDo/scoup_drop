require "test_helper"

module Sprints
  class SnapshotWriterTest < ActiveSupport::TestCase
    test "updates the same sprint and date instead of creating a duplicate" do
      sprint = sprints(:current)

      assert_no_difference("SprintDailySnapshot.count") do
        SnapshotWriter.new(sprint, date: Date.new(2026, 6, 1)).call
      end

      assert_equal BigDecimal("8.5"), sprint.daily_snapshots.find_by!(snapshot_date: "2026-06-01").planned_sp
    end
  end
end
