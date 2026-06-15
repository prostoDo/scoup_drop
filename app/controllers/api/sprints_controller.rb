module Api
  class SprintsController < BaseController
    def index
      sprints = Sprint.ordered.includes(sprint_issues: :issue)
      render json: { items: sprints.map { |sprint| SprintSerializer.summary(sprint) } }
    end

    def show
      sprint = Sprint.includes(sprint_issues: :issue).find(params[:id])
      render json: SprintSerializer.detail(sprint)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "not_found" }, status: :not_found
    end
  end
end
