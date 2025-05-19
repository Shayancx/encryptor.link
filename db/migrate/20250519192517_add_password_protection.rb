class AddPasswordProtection < ActiveRecord::Migration[8.0]
  def change
    # Only add columns if they don't already exist
    unless column_exists?(:encrypted_payloads, :password_protected)
      add_column :encrypted_payloads, :password_protected, :boolean, default: false, null: false
    end

    unless column_exists?(:encrypted_payloads, :password_salt)
      add_column :encrypted_payloads, :password_salt, :binary
    end
  end
end
