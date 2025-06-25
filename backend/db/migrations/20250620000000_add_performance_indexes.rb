# frozen_string_literal: true

Sequel.migration do
  up do
    # Add indexes for better performance
    alter_table(:encrypted_files) do
      add_index %i[created_at account_id], name: :idx_files_created_account
      add_index %i[ip_address created_at], name: :idx_files_ip_created
    end

    alter_table(:accounts) do
      add_index :created_at, name: :idx_accounts_created
      add_index %i[email password_hash], name: :idx_accounts_auth
    end

    alter_table(:access_logs) do
      add_index :accessed_at, name: :idx_logs_accessed
    end
  end

  down do
    alter_table(:encrypted_files) do
      drop_index :idx_files_created_account
      drop_index :idx_files_ip_created
    end

    alter_table(:accounts) do
      drop_index :idx_accounts_created
      drop_index :idx_accounts_auth
    end

    alter_table(:access_logs) do
      drop_index :idx_logs_accessed
    end
  end
end
