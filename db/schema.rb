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

ActiveRecord::Schema[8.0].define(version: 2025_05_26_114405) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "action_text_rich_texts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "encrypted_files", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "encrypted_payload_id", null: false
    t.text "file_data", null: false
    t.string "file_name", null: false
    t.string "file_type"
    t.integer "file_size", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "compressed", default: false, null: false
    t.index ["encrypted_payload_id"], name: "idx_encrypted_files_payload"
    t.index ["encrypted_payload_id"], name: "index_encrypted_files_on_encrypted_payload_id"
  end

  create_table "encrypted_payloads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.binary "ciphertext", null: false
    t.binary "nonce", null: false
    t.datetime "expires_at", null: false
    t.integer "remaining_views", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "password_protected", default: false, null: false
    t.binary "password_salt"
    t.index ["expires_at", "remaining_views"], name: "idx_payloads_cleanup"
    t.index ["expires_at"], name: "index_encrypted_payloads_on_expires_at"
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "user_message_metadata", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "message_id"
    t.text "encrypted_label"
    t.text "encrypted_filename"
    t.integer "file_size"
    t.string "message_type"
    t.datetime "original_expiry"
    t.integer "accessed_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_user_message_metadata_on_created_at"
    t.index ["message_id"], name: "index_user_message_metadata_on_message_id"
    t.index ["original_expiry"], name: "index_user_message_metadata_on_original_expiry"
    t.index ["user_id", "created_at"], name: "index_user_message_metadata_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_user_message_metadata_on_user_id"
  end

  create_table "user_preferences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.integer "default_ttl"
    t.integer "default_views"
    t.string "theme_preference"
    t.text "encrypted_settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_preferences_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "encrypted_files", "encrypted_payloads"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_message_metadata", "users"
  add_foreign_key "user_preferences", "users"
end
