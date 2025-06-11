class AddMissingFieldsToMessages < ActiveRecord::Migration[8.0]
  def change
    # Add these columns if they don't exist
    add_column :messages, :view_count, :integer, default: 0 unless column_exists?(:messages, :view_count)
    add_column :messages, :max_views, :integer unless column_exists?(:messages, :max_views)
    add_column :messages, :deleted, :boolean, default: false unless column_exists?(:messages, :deleted)
  end
end
