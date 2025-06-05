class AddBurnAfterReadingToEncryptedPayloads < ActiveRecord::Migration[8.0]
  def change
    add_column :encrypted_payloads, :burn_after_reading, :boolean, default: false, null: false
    add_index :encrypted_payloads, :burn_after_reading
  end
end
