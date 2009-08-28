require 'rubygems'

class TableMonitor < Scout::Plugin

  def build_report
    # need the mysql gem
    begin
      require 'mysql'
    rescue LoadError => e
      return errors << {:subject => "Unable to gather Mysql query statistics",
                           :body => "Unable to find the mysql gem. Please install the gem (sudo gem install mysql)" }
    end

    user = @options['user'] || 'root'
    password, host, port, socket, database = @options.values_at( *%w(password host port socket database) ).map { |v| v.to_s.strip == '' ? nil : v}
    begin
      mysql = Mysql.connect(host, user, password, database, port.to_i, socket)
    rescue Mysql::Error => e
      return errors << {:subject => "Unable to connect to MySQL Server.",
                           :body => "Scout was unable to connect to the mysql server with the following options: #{@options.inspect}: #{e.backtrace}"}
    end

    tables = (@options['table_names'] || '').split(',')
    ages = {}
    for table in tables
      table.strip!
      table_name = mysql.escape_string table
      res = mysql.query("SELECT (UTC_TIMESTAMP-created_at) FROM #{table_name} order BY id DESC LIMIT 1")
      ages[table] = res.fetch_row.first.to_f / 60.0
      res.free
    end
    report ages  unless ages.empty?
  end

end
