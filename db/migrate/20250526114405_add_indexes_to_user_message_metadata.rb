class AddIndexesToUserMessageMetadata < ActiveRecord::Migration[8.0]
  def change
    add_index :user_message_metadata, :created_at unless index_exists?(:user_message_metadata, :created_at)
    add_index :user_message_metadata, :original_expiry unless index_exists?(:user_message_metadata, :original_expiry)
    add_index :user_message_metadata, [ :user_id, :created_at ] unless index_exists?(:user_message_metadata, [ :user_id, :created_at ])
  end
end
