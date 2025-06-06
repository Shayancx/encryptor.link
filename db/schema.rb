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

ActiveRecord::Schema[8.0].define(version: 2025_06_08_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "account_login_change_keys", id: :uuid, default: nil, force: :cascade do |t|
    t.string "key", null: false
    t.string "login", null: false
    t.datetime "deadline", null: false
  end

  create_table "account_password_reset_keys", id: :uuid, default: nil, force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "account_pgp_challenges", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "nonce", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "account_id" ], name: "index_account_pgp_challenges_on_account_id"
  end

  create_table "account_remember_keys", id: :uuid, default: nil, force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
  end

  create_table "account_verification_keys", id: :uuid, default: nil, force: :cascade do |t|
    t.string "key", null: false
    t.datetime "requested_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "status", default: 1, null: false
    t.citext "email"
    t.string "password_hash"
    t.text "pgp_public_key"
    t.string "pgp_fingerprint"
    t.index [ "email" ], name: "index_accounts_on_email", unique: true, where: "((email IS NOT NULL) AND (status = ANY (ARRAY[1, 2])))"
    t.index [ "pgp_fingerprint" ], name: "index_accounts_on_pgp_fingerprint", unique: true
    t.check_constraint "email ~ '^[^,;@ \r\n]+@[^,@; \r\n]+.[^,@; \r\n]+$'::citext", name: "valid_email"
  end

  create_table "action_text_rich_texts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "record_type", "record_id", "name" ], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index [ "blob_id" ], name: "index_active_storage_attachments_on_blob_id"
    t.index [ "record_type", "record_id", "name", "blob_id" ], name: "index_active_storage_attachments_uniqueness", unique: true
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
    t.index [ "key" ], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index [ "blob_id", "variation_digest" ], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "email" ], name: "index_admin_users_on_email", unique: true
    t.index [ "role" ], name: "index_admin_users_on_role"
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
    t.index [ "created_at" ], name: "idx_audit_logs_critical_time", where: "((severity)::text = ANY ((ARRAY['warning'::character varying, 'critical'::character varying])::text[]))"
    t.index [ "created_at" ], name: "index_audit_logs_on_created_at"
    t.index [ "event_type", "created_at" ], name: "idx_audit_logs_event_time"
    t.index [ "event_type" ], name: "index_audit_logs_on_event_type"
    t.index [ "ip_address", "created_at" ], name: "idx_audit_logs_ip_time"
    t.index [ "ip_address", "created_at" ], name: "index_audit_logs_on_ip_and_time"
    t.index [ "payload_id" ], name: "index_audit_logs_on_payload_id"
    t.index [ "severity", "created_at" ], name: "idx_audit_logs_severity_time"
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
    t.index [ "certificate_hash" ], name: "index_destruction_certificates_on_certificate_hash", unique: true
    t.index [ "certificate_id" ], name: "index_destruction_certificates_on_certificate_id", unique: true
    t.index [ "created_at" ], name: "index_destruction_certificates_on_created_at"
    t.index [ "encrypted_payload_id" ], name: "index_destruction_certificates_on_encrypted_payload_id"
    t.check_constraint "length(certificate_data) > 0", name: "check_certificate_data_not_empty"
  end

  create_table "encrypted_files", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "encrypted_payload_id", null: false
    t.text "file_data", null: false
    t.string "file_name", null: false
    t.string "file_type"
    t.integer "file_size", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "file_data_checksum"
    t.index [ "encrypted_payload_id" ], name: "idx_encrypted_files_payload"
    t.index [ "encrypted_payload_id" ], name: "index_encrypted_files_on_encrypted_payload_id"
    t.index [ "file_data_checksum" ], name: "index_encrypted_files_on_file_data_checksum"
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
    t.string "ciphertext_checksum"
    t.string "nonce_checksum"
    t.index [ "burn_after_reading" ], name: "index_encrypted_payloads_on_burn_after_reading"
    t.index [ "ciphertext_checksum" ], name: "index_encrypted_payloads_on_ciphertext_checksum"
    t.index [ "created_at" ], name: "idx_payloads_created_at"
    t.index [ "expires_at", "remaining_views" ], name: "idx_payloads_cleanup"
    t.index [ "expires_at" ], name: "index_encrypted_payloads_on_expires_at"
  end

  add_foreign_key "account_login_change_keys", "accounts", column: "id"
  add_foreign_key "account_password_reset_keys", "accounts", column: "id"
  add_foreign_key "account_remember_keys", "accounts", column: "id"
  add_foreign_key "account_verification_keys", "accounts", column: "id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "encrypted_files", "encrypted_payloads"
end
