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

ActiveRecord::Schema[8.0].define(version: 2025_05_15_125306) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "encrypted_files", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "encrypted_payload_id", null: false
    t.text "file_data", null: false
    t.string "file_name", null: false
    t.string "file_type"
    t.integer "file_size", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["encrypted_payload_id"], name: "index_encrypted_files_on_encrypted_payload_id"
  end

  create_table "encrypted_payloads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.binary "ciphertext", null: false
    t.binary "nonce", null: false
    t.datetime "expires_at", null: false
    t.integer "remaining_views", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_encrypted_payloads_on_expires_at"
  end

  add_foreign_key "encrypted_files", "encrypted_payloads"
end
