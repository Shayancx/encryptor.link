class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs, id: :uuid, default: -> { 'gen_random_uuid()' } do |t|
      t.string :event_type, null: false
      t.string :endpoint
      t.uuid :payload_id
      t.string :ip_address
      t.string :user_agent
      t.json :metadata
      t.string :severity, default: 'info'
      t.timestamps
    end

    add_index :audit_logs, :event_type
    add_index :audit_logs, :created_at
    add_index :audit_logs, [:ip_address, :created_at]
    add_index :audit_logs, :payload_id
  end
end
