module Api
  class SyncController < BaseController
    def create
      YouTrack::SyncService.new(mode: :manual).call
      render json: { status: "success" }
    rescue YouTrack::SyncInProgress
      render json: { status: "failed", error: "sync_in_progress" }, status: :conflict
    rescue YouTrack::Error, KeyError, ActiveRecord::ActiveRecordError => error
      Rails.logger.error("YouTrack synchronization failed: #{error.class}: #{error.message}")
      render json: { status: "failed", error: "youtrack_sync_failed" }, status: :bad_gateway
    end
  end
end
