class ChangeFileDataToText < ActiveRecord::Migration[8.0]
  def up
    # First, backup any existing data
    execute <<-SQL
      CREATE TEMP TABLE temp_file_data AS 
      SELECT id, encode(file_data::bytea, 'base64') as file_data_base64 
      FROM encrypted_files 
      WHERE file_data IS NOT NULL AND file_data != '';
    SQL
    
    # Change column type to text
    change_column :encrypted_files, :file_data, :text
    
    # Restore data as base64
    execute <<-SQL
      UPDATE encrypted_files 
      SET file_data = temp.file_data_base64 
      FROM temp_file_data temp 
      WHERE encrypted_files.id = temp.id;
    SQL
    
    # Drop temp table
    execute "DROP TABLE temp_file_data;"
  end
  
  def down
    # This is destructive, be careful
    change_column :encrypted_files, :file_data, :binary
  end
end
