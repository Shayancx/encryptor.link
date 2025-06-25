# frozen_string_literal: true

Sequel.migration do
  up do
    # Add security audit log table
    create_table?(:security_audit_logs) do
      primary_key :id
      String :event_type, null: false
      String :ip_address
      String :user_identifier
      Text :details
      DateTime :created_at, null: false

      index :event_type
      index :created_at
    end

    # Add password attempt tracking
    create_table?(:password_attempts) do
      primary_key :id
      String :identifier, null: false
      Integer :attempt_count, default: 0
      DateTime :last_attempt
      DateTime :locked_until

      index :identifier, unique: true
    end

    # Log migration
    from(:security_audit_logs).insert(
      event_type: 'migration',
      details: 'Enhanced password security migration applied',
      created_at: Time.now
    )
  end

  down do
    drop_table?(:password_attempts)
    drop_table?(:security_audit_logs)
  end
end
