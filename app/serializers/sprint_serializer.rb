class SprintSerializer
  class << self
    def summary(sprint)
      metrics = Sprints::MetricsCalculator.new(sprint).call

      {
        id: sprint.id,
        name: sprint.name,
        start_date: sprint.start_date,
        end_date: sprint.end_date,
        archived: sprint.archived
      }.merge(serialize_metrics(metrics).slice(
        :issues_count,
        :planned_sp,
        :completed_sp,
        :added_sp,
        :dropped_sp,
        :completion_rate,
        :scope_drop_rate,
        :scope_stability_index
      ))
    end

    def detail(sprint)
      associations = sprint.sprint_issues.sort_by { |item| item.issue.key }
      calculator = Sprints::MetricsCalculator.new(sprint, associations: associations)

      {
        sprint: {
          id: sprint.id,
          name: sprint.name,
          start_date: sprint.start_date,
          end_date: sprint.end_date,
          archived: sprint.archived,
          initial_scope_inferred: sprint.initial_scope_inferred?
        },
        metrics: serialize_metrics(calculator.call),
        developers: calculator.developers.map { |metrics| serialize_metrics(metrics) },
        issues: associations.map { |association| serialize_issue(association) }
      }
    end

    private

    def serialize_metrics(metrics)
      metrics.transform_values do |value|
        value.is_a?(BigDecimal) ? number(value) : value
      end
    end

    def serialize_issue(association)
      issue = association.issue
      {
        id: issue.id,
        key: issue.key,
        summary: issue.summary,
        url: issue.url,
        assignee_name: issue.assignee_name.presence || "Без исполнителя",
        status: issue.status,
        estimation_be: issue.estimation_be && number(issue.estimation_be),
        has_estimation: issue.has_estimation,
        is_initial_scope: association.is_initial_scope,
        is_added_after_start: association.is_added_after_start,
        is_removed_from_sprint: association.is_removed_from_sprint,
        currently_in_sprint: association.currently_in_sprint
      }
    end

    def number(value)
      value.frac.zero? ? value.to_i : value.to_f
    end
  end
end
