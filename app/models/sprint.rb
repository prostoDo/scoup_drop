class Sprint < ApplicationRecord
  INITIAL_SCOPE_SOURCES = %w[sprint_start first_snapshot].freeze

  has_many :sprint_issues, dependent: :destroy
  has_many :issues, through: :sprint_issues
  has_many :daily_snapshots, class_name: "SprintDailySnapshot", dependent: :destroy

  validates :youtrack_id, :name, presence: true
  validates :youtrack_id, uniqueness: true
  validates :initial_scope_source, inclusion: { in: INITIAL_SCOPE_SOURCES }, allow_nil: true

  scope :ordered, -> { order(start_date: :desc, id: :desc) }

  def initial_scope_inferred?
    initial_scope_source == "first_snapshot"
  end
end
