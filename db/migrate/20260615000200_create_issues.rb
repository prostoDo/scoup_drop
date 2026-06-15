class CreateIssues < ActiveRecord::Migration[8.1]
  def change
    create_table :issues do |t|
      t.string :youtrack_id, null: false
      t.string :key, null: false
      t.string :summary, null: false
      t.string :url, null: false
      t.string :assignee_name
      t.string :status
      t.decimal :estimation_be, precision: 12, scale: 2
      t.boolean :has_estimation, null: false, default: false

      t.timestamps
    end

    add_index :issues, :youtrack_id, unique: true
    add_index :issues, :key, unique: true
  end
end
