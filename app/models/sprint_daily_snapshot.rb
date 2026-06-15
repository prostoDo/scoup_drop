class SprintDailySnapshot < ApplicationRecord
  belongs_to :sprint

  validates :snapshot_date, presence: true, uniqueness: { scope: :sprint_id }
end
