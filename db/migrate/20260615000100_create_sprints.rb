class CreateSprints < ActiveRecord::Migration[8.1]
  def change
    create_table :sprints do |t|
      t.string :youtrack_id, null: false
      t.string :name, null: false
      t.date :start_date
      t.date :end_date
      t.boolean :archived, null: false, default: false
      t.datetime :initial_scope_captured_at
      t.string :initial_scope_source

      t.timestamps
    end

    add_index :sprints, :youtrack_id, unique: true
    add_index :sprints, %i[start_date end_date]
  end
end
