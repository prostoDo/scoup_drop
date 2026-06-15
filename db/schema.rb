# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_15_000400) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "issues", force: :cascade do |t|
    t.string "assignee_name"
    t.datetime "created_at", null: false
    t.decimal "estimation_be", precision: 12, scale: 2
    t.boolean "has_estimation", default: false, null: false
    t.string "key", null: false
    t.string "status"
    t.string "summary", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.string "youtrack_id", null: false
    t.index ["key"], name: "index_issues_on_key", unique: true
    t.index ["youtrack_id"], name: "index_issues_on_youtrack_id", unique: true
  end

  create_table "sprint_daily_snapshots", force: :cascade do |t|
    t.decimal "added_scope_rate", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "added_sp", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "completed_sp", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "completion_rate", precision: 8, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.decimal "dropped_sp", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "issues_count", default: 0, null: false
    t.decimal "planned_sp", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "remaining_sp", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "scope_change_rate", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "scope_drop_rate", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "scope_stability_index", precision: 8, scale: 2, default: "0.0", null: false
    t.date "snapshot_date", null: false
    t.bigint "sprint_id", null: false
    t.datetime "updated_at", null: false
    t.integer "without_estimation_count", default: 0, null: false
    t.index ["sprint_id", "snapshot_date"], name: "index_snapshots_on_sprint_and_date", unique: true
    t.index ["sprint_id"], name: "index_sprint_daily_snapshots_on_sprint_id"
  end

  create_table "sprint_issues", force: :cascade do |t|
    t.datetime "added_to_sprint_at"
    t.datetime "created_at", null: false
    t.boolean "currently_in_sprint", default: true, null: false
    t.boolean "is_added_after_start", default: false, null: false
    t.boolean "is_initial_scope", default: false, null: false
    t.boolean "is_removed_from_sprint", default: false, null: false
    t.bigint "issue_id", null: false
    t.datetime "removed_from_sprint_at"
    t.bigint "sprint_id", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id"], name: "index_sprint_issues_on_issue_id"
    t.index ["sprint_id", "currently_in_sprint"], name: "index_sprint_issues_on_sprint_id_and_currently_in_sprint"
    t.index ["sprint_id", "issue_id"], name: "index_sprint_issues_on_sprint_id_and_issue_id", unique: true
    t.index ["sprint_id"], name: "index_sprint_issues_on_sprint_id"
  end

  create_table "sprints", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", null: false
    t.date "end_date"
    t.datetime "initial_scope_captured_at"
    t.string "initial_scope_source"
    t.string "name", null: false
    t.date "start_date"
    t.datetime "updated_at", null: false
    t.string "youtrack_id", null: false
    t.index ["start_date", "end_date"], name: "index_sprints_on_start_date_and_end_date"
    t.index ["youtrack_id"], name: "index_sprints_on_youtrack_id", unique: true
  end

  add_foreign_key "sprint_daily_snapshots", "sprints"
  add_foreign_key "sprint_issues", "issues"
  add_foreign_key "sprint_issues", "sprints"
end
