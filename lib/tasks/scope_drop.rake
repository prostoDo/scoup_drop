namespace :scope_drop do
  desc "Synchronize active YouTrack sprints and write today's snapshots"
  task daily_snapshot: :environment do
    YouTrack::SyncService.new(mode: :daily).call
    Rails.logger.info("Scope Drop daily snapshot completed")
  rescue YouTrack::SyncInProgress
    Rails.logger.warn("Scope Drop daily snapshot skipped: synchronization is already running")
  end
end
