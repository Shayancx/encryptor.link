class CreateEncryptedPayloads < ActiveRecord::Migration[8.0]
  def change
    create_table :encrypted_payloads, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.binary   :ciphertext,      null: false
      t.binary   :nonce,           null: false
      t.datetime :expires_at,      null: false
      t.integer  :remaining_views, null: false, default: 1
      t.timestamps
    end
    add_index :encrypted_payloads, :expires_at
  end
end
