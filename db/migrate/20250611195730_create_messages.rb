class CreateMessages < ActiveRecord::Migration[6.1]
  def change
    create_table :messages, id: :uuid do |t|
      t.text :encrypted_data, null: false
      t.text :metadata
      t.datetime :expires_at
      t.integer :view_count, default: 0
      t.boolean :deleted, default: false
      t.timestamps
    end
    
    add_index :messages, :expires_at
  end
end
