module Sprints
  class MetricsCalculator
    METRIC_KEYS = %i[
      planned_sp completed_sp added_sp dropped_sp remaining_sp completion_rate
      scope_drop_rate added_scope_rate scope_change_rate scope_stability_index
      issues_count without_estimation_count
    ].freeze

    def initialize(sprint, associations: nil)
      @sprint = sprint
      @associations = associations || sprint.sprint_issues.includes(:issue).to_a
    end

    def call
      planned = sum(initial_scope)
      completed = sum(estimated.select { |item| done?(item.issue) })
      added = sum(added_scope)
      dropped = sum(initial_scope.reject { |item| done?(item.issue) })
      remaining = sum(current.reject { |item| done?(item.issue) })
      scope_change = rate(added + dropped, planned)

      {
        planned_sp: planned,
        completed_sp: completed,
        added_sp: added,
        dropped_sp: dropped,
        remaining_sp: remaining,
        completion_rate: rate(completed, planned),
        scope_drop_rate: rate(dropped, planned),
        added_scope_rate: rate(added, planned),
        scope_change_rate: scope_change,
        scope_stability_index: [ BigDecimal("100") - scope_change, BigDecimal("0") ].max,
        issues_count: current.size,
        without_estimation_count: current.count { |item| !item.issue.has_estimation? }
      }
    end

    def developers
      @associations.group_by { |item| item.issue.assignee_name.presence || "Без исполнителя" }
        .sort_by { |name, _| name }
        .map do |name, items|
          metrics = self.class.new(@sprint, associations: items).call
          metrics.merge(assignee_name: name)
        end
    end

    private

    def current
      @current ||= @associations.select(&:currently_in_sprint?)
    end

    def estimated
      @estimated ||= @associations.select { |item| item.issue.has_estimation? }
    end

    def initial_scope
      @initial_scope ||= estimated.select(&:is_initial_scope?)
    end

    def added_scope
      @added_scope ||= estimated.select(&:is_added_after_start?)
    end

    def done?(issue)
      issue.status == ENV.fetch("YOUTRACK_DONE_STATUS_NAME", "Done")
    end

    def sum(items)
      items.sum(BigDecimal("0")) { |item| item.issue.estimation_be || BigDecimal("0") }
    end

    def rate(numerator, denominator)
      return BigDecimal("0") if denominator.zero?

      ((numerator / denominator) * 100).round(2)
    end
  end
end
