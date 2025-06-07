class CreateDestructionCertificates < ActiveRecord::Migration[8.0]
  def change
    create_table :destruction_certificates, id: :uuid do |t|
      t.string :certificate_id, null: false
      t.string :certificate_hash, null: false
      t.text :certificate_data, null: false
      t.json :payload_metadata
      t.string :destruction_reason
      t.references :encrypted_payload, type: :uuid, foreign_key: false

      t.timestamps
    end

    add_index :destruction_certificates, :certificate_id, unique: true
    add_index :destruction_certificates, :certificate_hash, unique: true
    add_index :destruction_certificates, :created_at
  end
end
