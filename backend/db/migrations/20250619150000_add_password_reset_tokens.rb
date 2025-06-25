# frozen_string_literal: true

Sequel.migration do
  up do
    create_table?(:password_reset_tokens) do
      primary_key :id
      foreign_key :account_id, :accounts, null: false, on_delete: :cascade
      String :token, null: false, unique: true, size: 64
      DateTime :expires_at, null: false
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      Boolean :used, default: false

      index :token, unique: true
      index :account_id
      index :expires_at
    end

    # Clean up expired tokens periodically
    create_table?(:system_tasks) do
      primary_key :id
      String :task_name, null: false, unique: true
      DateTime :last_run_at
      Integer :interval_seconds, default: 3600

      index :task_name, unique: true
    end

    # Insert cleanup task
    from(:system_tasks).insert(
      task_name: 'cleanup_expired_reset_tokens',
      interval_seconds: 3600
    )
  end

  down do
    drop_table?(:password_reset_tokens)
    drop_table?(:system_tasks)
  end
end
