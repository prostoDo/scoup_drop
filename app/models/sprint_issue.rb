class SprintIssue < ApplicationRecord
  belongs_to :sprint
  belongs_to :issue

  validates :issue_id, uniqueness: { scope: :sprint_id }

  scope :current, -> { where(currently_in_sprint: true) }
  scope :initial_scope, -> { where(is_initial_scope: true) }
  scope :added_after_start, -> { where(is_added_after_start: true) }
  scope :removed, -> { where(is_removed_from_sprint: true) }
end
