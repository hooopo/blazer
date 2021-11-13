module Blazer
  class Visitor < Record
    before_create do 
      self.database = SecureRandom.hex(4)
      self.password = SecureRandom.hex(8)
      self.user     = SecureRandom.hex(4)
      ActiveRecord::Base.connection.execute("CREATE USER '#{self.user}' IDENTIFIED BY '#{self.password}';")
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{database};")
      ActiveRecord::Base.connection.execute("GRANT ALL ON #{database}.* TO '#{user}';")
    end

    def db_config
      main_config = ActiveRecord::Base.connection.instance_eval{@config}
    end

    def settings
      base = ActiveRecord::Base.connection.instance_eval{@config}
      {
        "data_sources"=> { 
          database => {
            "database"=> database,
            "url"=>"mysql2://#{user}:#{password}@#{base[:host]}:#{base[:port]}/#{database}"
          }
        }
      }
    end

    def data_sources
      ds = Hash.new { |hash, key| raise Blazer::Error, "Unknown data source: #{key}" }
      settings["data_sources"].each do |id, s|
        ds[id] = Blazer::DataSource.new(id, s)
      end
      ds
    end
  end
end

