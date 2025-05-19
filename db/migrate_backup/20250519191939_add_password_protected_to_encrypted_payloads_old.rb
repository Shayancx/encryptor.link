class AddPasswordProtectedToEncryptedPayloads < ActiveRecord::Migration[8.0]
  def change
    add_column :encrypted_payloads, :password_protected, :boolean, default: false, null: false
    add_column :encrypted_payloads, :password_salt, :binary
  end
end
