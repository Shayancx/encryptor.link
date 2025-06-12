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

ActiveRecord::Schema[8.0].define(version: 2025_06_12_143751) do
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

  create_table "admin_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["role"], name: "index_admin_users_on_role"
  end

  create_table "audit_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "event_type", null: false
    t.string "endpoint"
    t.uuid "payload_id"
    t.string "ip_address"
    t.string "user_agent"
    t.json "metadata"
    t.string "severity", default: "info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "((metadata)::jsonb)", name: "idx_audit_logs_metadata_gin", using: :gin
    t.index ["created_at"], name: "idx_audit_logs_critical_time", where: "((severity)::text = ANY (ARRAY[('warning'::character varying)::text, ('critical'::character varying)::text]))"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["event_type", "created_at"], name: "idx_audit_logs_event_time"
    t.index ["event_type"], name: "index_audit_logs_on_event_type"
    t.index ["ip_address", "created_at"], name: "idx_audit_logs_ip_time"
    t.index ["ip_address", "created_at"], name: "index_audit_logs_on_ip_and_time"
    t.index ["payload_id"], name: "index_audit_logs_on_payload_id"
    t.index ["severity", "created_at"], name: "idx_audit_logs_severity_time"
  end

  create_table "destruction_certificates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "certificate_id", null: false
    t.string "certificate_hash", null: false
    t.text "certificate_data", null: false
    t.json "payload_metadata"
    t.string "destruction_reason"
    t.uuid "encrypted_payload_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["certificate_hash"], name: "index_destruction_certificates_on_certificate_hash", unique: true
    t.index ["certificate_id"], name: "index_destruction_certificates_on_certificate_id", unique: true
    t.index ["created_at"], name: "index_destruction_certificates_on_created_at"
    t.index ["encrypted_payload_id"], name: "index_destruction_certificates_on_encrypted_payload_id"
    t.check_constraint "length(certificate_data) > 0", name: "check_certificate_data_not_empty"
  end

  create_table "encrypted_files", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "encrypted_payload_id", null: false
    t.text "file_data"
    t.string "file_name", null: false
    t.string "file_type"
    t.integer "file_size", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "message_id"
    t.string "file_id", default: -> { "gen_random_uuid()" }, null: false
    t.string "name"
    t.text "file_metadata"
    t.string "encrypted_blob_key"
    t.index ["encrypted_blob_key"], name: "index_encrypted_files_on_encrypted_blob_key"
    t.index ["encrypted_payload_id"], name: "idx_encrypted_files_payload"
    t.index ["encrypted_payload_id"], name: "index_encrypted_files_on_encrypted_payload_id"
    t.index ["file_id"], name: "index_encrypted_files_on_file_id", unique: true
    t.index ["message_id"], name: "index_encrypted_files_on_message_id"
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
    t.boolean "burn_after_reading", default: false, null: false
    t.text "encrypted_data"
    t.integer "max_views"
    t.string "password_digest"
    t.index ["burn_after_reading"], name: "index_encrypted_payloads_on_burn_after_reading"
    t.index ["created_at"], name: "idx_payloads_created_at"
    t.index ["expires_at", "remaining_views"], name: "idx_payloads_cleanup"
    t.index ["expires_at"], name: "index_encrypted_payloads_on_expires_at"
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "encrypted_data", null: false
    t.text "metadata"
    t.datetime "expires_at", precision: nil
    t.integer "view_count", default: 0
    t.boolean "deleted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "max_views"
    t.index ["expires_at"], name: "index_messages_on_expires_at"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "encrypted_files", "encrypted_payloads"
  add_foreign_key "encrypted_files", "messages"
end
