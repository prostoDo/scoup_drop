class CreateSprintIssues < ActiveRecord::Migration[8.1]
  def change
    create_table :sprint_issues do |t|
      t.references :sprint, null: false, foreign_key: true
      t.references :issue, null: false, foreign_key: true
      t.boolean :is_initial_scope, null: false, default: false
      t.boolean :is_added_after_start, null: false, default: false
      t.boolean :is_removed_from_sprint, null: false, default: false
      t.boolean :currently_in_sprint, null: false, default: true
      t.datetime :added_to_sprint_at
      t.datetime :removed_from_sprint_at

      t.timestamps
    end

    add_index :sprint_issues, %i[sprint_id issue_id], unique: true
    add_index :sprint_issues, %i[sprint_id currently_in_sprint]
  end
end
