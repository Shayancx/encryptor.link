class FixEncryptedPayloadsConstraints < ActiveRecord::Migration[8.0]
  def up
    # Make nonce nullable temporarily
    change_column_null :encrypted_payloads, :nonce, true
    
    # Update existing records with null nonce
    EncryptedPayload.where(nonce: nil).find_each do |payload|
      payload.update_column(:nonce, SecureRandom.random_bytes(12))
    end
    
    # Make nonce not nullable again
    change_column_null :encrypted_payloads, :nonce, false
  end
  
  def down
    # This migration is not reversible
  end
end
