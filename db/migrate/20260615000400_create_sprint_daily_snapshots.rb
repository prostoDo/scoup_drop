class CreateSprintDailySnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :sprint_daily_snapshots do |t|
      t.references :sprint, null: false, foreign_key: true
      t.date :snapshot_date, null: false
      t.decimal :planned_sp, precision: 12, scale: 2, null: false, default: 0
      t.decimal :completed_sp, precision: 12, scale: 2, null: false, default: 0
      t.decimal :added_sp, precision: 12, scale: 2, null: false, default: 0
      t.decimal :dropped_sp, precision: 12, scale: 2, null: false, default: 0
      t.decimal :remaining_sp, precision: 12, scale: 2, null: false, default: 0
      t.decimal :completion_rate, precision: 8, scale: 2, null: false, default: 0
      t.decimal :scope_drop_rate, precision: 8, scale: 2, null: false, default: 0
      t.decimal :added_scope_rate, precision: 8, scale: 2, null: false, default: 0
      t.decimal :scope_change_rate, precision: 8, scale: 2, null: false, default: 0
      t.decimal :scope_stability_index, precision: 8, scale: 2, null: false, default: 0
      t.integer :issues_count, null: false, default: 0
      t.integer :without_estimation_count, null: false, default: 0

      t.timestamps
    end

    add_index :sprint_daily_snapshots, %i[sprint_id snapshot_date],
      unique: true, name: "index_snapshots_on_sprint_and_date"
  end
end
