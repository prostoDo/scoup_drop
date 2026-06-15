module Sprints
  class SnapshotWriter
    def initialize(sprint, date: Time.zone.today)
      @sprint = sprint
      @date = date
    end

    def call
      metrics = MetricsCalculator.new(@sprint).call
      snapshot = @sprint.daily_snapshots.find_or_initialize_by(snapshot_date: @date)
      snapshot.assign_attributes(metrics.slice(*MetricsCalculator::METRIC_KEYS))
      snapshot.save!
      snapshot
    end
  end
end
