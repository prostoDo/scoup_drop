class Issue < ApplicationRecord
  has_many :sprint_issues, dependent: :destroy
  has_many :sprints, through: :sprint_issues

  validates :youtrack_id, :key, :summary, :url, presence: true
  validates :youtrack_id, :key, uniqueness: true
  validates :estimation_be, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :normalize_estimation

  private

  def normalize_estimation
    self.has_estimation = estimation_be.present?
  end
end
