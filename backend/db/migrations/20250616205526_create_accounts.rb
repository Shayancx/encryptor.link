# frozen_string_literal: true

Sequel.migration do
  up do
    # Accounts table
    create_table(:accounts) do
      primary_key :id
      String :email, null: false, unique: true
      String :status_id, null: false, default: 'verified' # Skip email verification for now
      String :password_hash, null: false, size: 60
      DateTime :created_at, null: false
      DateTime :updated_at
      DateTime :last_login_at

      index :email, unique: true
      index :status_id
    end

    # Account login change table (for email changes)
    create_table(:account_login_change_keys) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :key, null: false
      String :login, null: false
      DateTime :deadline, null: false
    end

    # Password reset keys
    create_table(:account_password_reset_keys) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :key, null: false
      DateTime :deadline, null: false
      DateTime :email_last_sent, null: false, default: Sequel::CURRENT_TIMESTAMP
    end

    # Active sessions tracking
    create_table(:account_active_session_keys) do
      foreign_key :account_id, :accounts, type: :Bignum, null: false
      String :session_id, null: false
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :last_use, null: false, default: Sequel::CURRENT_TIMESTAMP

      primary_key %i[account_id session_id]
      index :account_id
    end

    # Update encrypted_files to optionally reference accounts
    alter_table(:encrypted_files) do
      add_foreign_key :account_id, :accounts, type: :Bignum, null: true
      add_index :account_id
    end
  end

  down do
    alter_table(:encrypted_files) do
      drop_foreign_key :account_id
    end

    drop_table(:account_active_session_keys)
    drop_table(:account_password_reset_keys)
    drop_table(:account_login_change_keys)
    drop_table(:accounts)
  end
end
