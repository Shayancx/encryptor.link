module DatabaseHelpers
  def execute_sql(sql)
    ActiveRecord::Base.connection.execute(sql)
  end

  def disable_foreign_key_checks
    if ActiveRecord::Base.connection.adapter_name.downcase.include?('postgresql')
      execute_sql("SET session_replication_role = replica;")
    elsif ActiveRecord::Base.connection.adapter_name.downcase.include?('mysql')
      execute_sql("SET FOREIGN_KEY_CHECKS = 0;")
    end
  end

  def enable_foreign_key_checks
    if ActiveRecord::Base.connection.adapter_name.downcase.include?('postgresql')
      execute_sql("SET session_replication_role = DEFAULT;")
    elsif ActiveRecord::Base.connection.adapter_name.downcase.include?('mysql')
      execute_sql("SET FOREIGN_KEY_CHECKS = 1;")
    end
  end
end

RSpec.configure do |config|
  config.include DatabaseHelpers
end
