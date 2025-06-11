#!/usr/bin/env ruby
require_relative '../config/environment'

# Display table schema
def display_table_schema(table_name)
  puts "=== #{table_name.upcase} TABLE SCHEMA ==="
  if ActiveRecord::Base.connection.table_exists?(table_name)
    columns = ActiveRecord::Base.connection.columns(table_name)
    columns.each do |column|
      puts "#{column.name} (#{column.type}#{column.null ? '' : ', not null'})"
    end
  else
    puts "Table doesn't exist!"
  end
  puts "\n"
end

# Check encrypted_payloads table
display_table_schema(:encrypted_payloads)

# Check encrypted_files table
display_table_schema(:encrypted_files)
