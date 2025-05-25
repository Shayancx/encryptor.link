class CreateUserMessageMetadata < ActiveRecord::Migration[8.0]
  def change
    create_table :user_message_metadata, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.uuid :message_id
      t.text :encrypted_label
      t.text :encrypted_filename
      t.integer :file_size
      t.string :message_type
      t.datetime :created_at
      t.datetime :original_expiry
      t.integer :accessed_count

      t.timestamps
    end
    add_index :user_message_metadata, :message_id
  end
end
