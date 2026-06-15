require "test_helper"

module Sprints
  class MetricsCalculatorTest < ActiveSupport::TestCase
    test "calculates the MVP metrics and excludes unestimated issues from points" do
      metrics = MetricsCalculator.new(sprints(:current)).call

      assert_equal BigDecimal("8.5"), metrics[:planned_sp]
      assert_equal BigDecimal("5"), metrics[:completed_sp]
      assert_equal BigDecimal("2"), metrics[:added_sp]
      assert_equal BigDecimal("3.5"), metrics[:dropped_sp]
      assert_equal BigDecimal("5.5"), metrics[:remaining_sp]
      assert_equal BigDecimal("58.82"), metrics[:completion_rate]
      assert_equal BigDecimal("41.18"), metrics[:scope_drop_rate]
      assert_equal BigDecimal("23.53"), metrics[:added_scope_rate]
      assert_equal BigDecimal("64.71"), metrics[:scope_change_rate]
      assert_equal BigDecimal("35.29"), metrics[:scope_stability_index]
      assert_equal 4, metrics[:issues_count]
      assert_equal 1, metrics[:without_estimation_count]
    end

    test "returns zero rates when planned scope is zero" do
      sprint = Sprint.create!(youtrack_id: "zero", name: "Zero")

      metrics = MetricsCalculator.new(sprint).call

      assert_equal BigDecimal("0"), metrics[:completion_rate]
      assert_equal BigDecimal("0"), metrics[:scope_drop_rate]
      assert_equal BigDecimal("100"), metrics[:scope_stability_index]
    end

    test "groups metrics by developer and uses a fallback name" do
      developers = MetricsCalculator.new(sprints(:current)).developers

      assert_equal [ "Ivan", "Olga", "Без исполнителя" ], developers.pluck(:assignee_name)
      assert_equal 2, developers.find { |item| item[:assignee_name] == "Ivan" }[:issues_count]
    end
  end
end
