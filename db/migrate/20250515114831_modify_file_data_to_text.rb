class ModifyFileDataToText < ActiveRecord::Migration[8.0]
  def change
    # First check if file_data column exists
    if column_exists?(:encrypted_payloads, :file_data)
      # Change the column from binary to text
      change_column :encrypted_payloads, :file_data, :text
    else
      # Add the column as text
      add_column :encrypted_payloads, :file_data, :text
      add_column :encrypted_payloads, :file_name, :string
      add_column :encrypted_payloads, :file_type, :string
      add_column :encrypted_payloads, :file_size, :integer
    end
  end
end
