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

ActiveRecord::Schema[7.2].define(version: 2025_10_18_014900) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "customers", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.integer "person_type", limit: 2, default: 0, null: false
    t.string "identification", limit: 50, null: false
    t.string "email", limit: 255, null: false
    t.string "phone", limit: 20
    t.string "address", limit: 500, null: false
    t.integer "active", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_customers_on_active"
    t.index ["email"], name: "index_customers_on_email"
    t.index ["identification"], name: "index_customers_on_identification", unique: true
  end

  create_table "outbox_messages", force: :cascade do |t|
    t.string "aggregate_id", null: false
    t.string "aggregate_type", null: false
    t.string "event_type", null: false
    t.text "payload", null: false
    t.integer "status", limit: 2, default: 0, null: false
    t.datetime "published_at", precision: nil
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aggregate_type", "aggregate_id"], name: "index_outbox_messages_on_aggregate_type_and_aggregate_id"
    t.index ["status", "created_at"], name: "index_outbox_messages_on_status_and_created_at"
  end
end
