module YouTrack
  class SyncService
    LOCK_NAME = "scope_drop_sync".freeze

    def initialize(mode: :manual, client: Client.new, now: Time.zone.now)
      @mode = mode
      @client = client
      @now = now
    end

    def call
      with_advisory_lock do
        payload = fetch_payload
        ActiveRecord::Base.transaction { apply(payload) }
      end
    end

    private

    def fetch_payload
      sprints = @client.sprints
      selected = sprints.select { |sprint| selected?(sprint) }
      issues_by_sprint = selected.to_h { |sprint| [ sprint.fetch("id"), @client.issues_for(sprint) ] }

      { sprints: sprints, selected_ids: selected.pluck("id"), issues_by_sprint: issues_by_sprint }
    end

    def selected?(raw)
      start_date = timestamp_date(raw["start"])
      end_date = timestamp_date(raw["finish"])
      return false unless start_date && end_date
      return true if @mode == :manual

      (start_date..end_date).cover?(@now.to_date)
    end

    def apply(payload)
      records = payload.fetch(:sprints).to_h do |raw|
        sprint = Sprint.find_or_initialize_by(youtrack_id: raw.fetch("id"))
        sprint.assign_attributes(
          name: raw.fetch("name"),
          start_date: timestamp_date(raw["start"]),
          end_date: timestamp_date(raw["finish"]),
          archived: raw["archived"] || false
        )
        sprint.save!
        [ raw.fetch("id"), sprint ]
      end

      payload.fetch(:selected_ids).each do |youtrack_id|
        sprint = records.fetch(youtrack_id)
        synchronize_issues(sprint, payload.fetch(:issues_by_sprint).fetch(youtrack_id))
        Sprints::SnapshotWriter.new(sprint, date: @now.to_date).call
      end
    end

    def synchronize_issues(sprint, issue_payloads)
      capture_baseline = sprint.initial_scope_captured_at.nil? &&
        sprint.start_date.present? &&
        @now.to_date >= sprint.start_date

      associations = sprint.sprint_issues.includes(:issue).index_by { |item| item.issue.youtrack_id }
      current_ids = []

      issue_payloads.each do |attributes|
        issue = Issue.find_or_initialize_by(youtrack_id: attributes.fetch(:youtrack_id))
        issue.assign_attributes(attributes)
        issue.save!
        current_ids << issue.youtrack_id

        association = associations[issue.youtrack_id] ||
          sprint.sprint_issues.build(issue: issue, added_to_sprint_at: @now)
        association.currently_in_sprint = true
        association.is_removed_from_sprint = false
        association.removed_from_sprint_at = nil
        association.is_initial_scope = true if capture_baseline
        if !capture_baseline &&
            sprint.initial_scope_captured_at.present? &&
            !association.is_initial_scope?
          association.is_added_after_start = true
        end
        association.save!
      end

      associations.each_value do |association|
        next unless association.currently_in_sprint?
        next if current_ids.include?(association.issue.youtrack_id)

        association.currently_in_sprint = false
        unless done?(association.issue)
          association.is_removed_from_sprint = true
          association.removed_from_sprint_at ||= @now
        end
        association.save!
      end

      return unless capture_baseline

      sprint.update!(
        initial_scope_captured_at: @now,
        initial_scope_source: @now.to_date > sprint.start_date ? "first_snapshot" : "sprint_start"
      )
    end

    def done?(issue)
      issue.status == ENV.fetch("YOUTRACK_DONE_STATUS_NAME", "Done")
    end

    def timestamp_date(value)
      return if value.blank?

      Time.zone.at(value.to_i / 1000.0).to_date
    end

    def with_advisory_lock
      connection = ActiveRecord::Base.connection
      locked = connection.select_value(
        "SELECT pg_try_advisory_lock(hashtext(#{connection.quote(LOCK_NAME)}))"
      )
      raise SyncInProgress unless ActiveModel::Type::Boolean.new.cast(locked)

      yield
    ensure
      if defined?(locked) && ActiveModel::Type::Boolean.new.cast(locked)
        connection.select_value(
          "SELECT pg_advisory_unlock(hashtext(#{connection.quote(LOCK_NAME)}))"
        )
      end
    end
  end
end
