module DatabaseHelpers
  def execute_sql(sql)
    ActiveRecord::Base.connection.execute(sql)
  end

  def disable_foreign_key_checks
    if postgresql?
      execute_sql("SET session_replication_role = replica;")
    elsif mysql?
      execute_sql("SET FOREIGN_KEY_CHECKS = 0;")
    elsif sqlite?
      execute_sql("PRAGMA foreign_keys = OFF;")
    end
  end

  def enable_foreign_key_checks
    if postgresql?
      execute_sql("SET session_replication_role = DEFAULT;")
    elsif mysql?
      execute_sql("SET FOREIGN_KEY_CHECKS = 1;")
    elsif sqlite?
      execute_sql("PRAGMA foreign_keys = ON;")
    end
  end

  def with_foreign_keys_disabled(&block)
    disable_foreign_key_checks
    begin
      yield
    ensure
      enable_foreign_key_checks
    end
  end

  private

  def postgresql?
    ActiveRecord::Base.connection.adapter_name.downcase.include?('postgresql')
  end

  def mysql?
    ActiveRecord::Base.connection.adapter_name.downcase.include?('mysql')
  end

  def sqlite?
    ActiveRecord::Base.connection.adapter_name.downcase.include?('sqlite')
  end
end

RSpec.configure do |config|
  config.include DatabaseHelpers
end
