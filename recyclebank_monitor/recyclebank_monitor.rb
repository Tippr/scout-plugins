require 'rubygems'

class RecyclebankMonitor < Scout::Plugin

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

    stats = { 'failure' => 0 }
    # Unclaimed transfers
    res = mysql.query "SELECT COUNT(*), SUM(amount)
                         FROM recycle_bank_transfers LEFT JOIN users
                           ON recycle_bank_transfers.user_id = users.id
LEFT JOIN recycle_bank_users
ON recycle_bank_users.user_id = users.id
WHERE recycle_bank_users.account IS NULL"
#                        WHERE users.recycle_bank_account IS NULL"
    row = res.fetch_row
    stats['unclaimed'], stats['unclaimed.amount'] = row[0].to_i, row[1].to_i
    res.free

    # Processing transfers
    res = mysql.query "SELECT gconomy_state, COUNT(*), SUM(amount)
                         FROM recycle_bank_transfers LEFT JOIN users
                           ON recycle_bank_transfers.user_id = users.id
LEFT JOIN recycle_bank_users
ON recycle_bank_users.user_id = users.id
WHERE recycle_bank_users.account IS NOT NULL
                     GROUP BY recycle_bank_transfers.gconomy_state"
#                        WHERE users.recycle_bank_account IS NOT NULL
    while row = res.fetch_row
      stats[row[0] || ''], stats["#{row[0]}.amount"] = row[1].to_i, row[2].to_i
    end
    res.free

    # Transfer ages
    res = mysql.query "SELECT gconomy_state, TIME_TO_SEC( TIMEDIFF(UTC_TIMESTAMP, MIN(recycle_bank_transfers.updated_at)) ) / (60 * 60.0)
                         FROM recycle_bank_transfers LEFT JOIN users
                           ON recycle_bank_transfers.user_id = users.id
LEFT JOIN recycle_bank_users
ON recycle_bank_users.user_id = users.id
WHERE recycle_bank_users.account IS NOT NULL
                          AND gconomy_state IN ('created','submitted')
                     GROUP BY recycle_bank_transfers.gconomy_state";
#                        WHERE users.recycle_bank_account IS NULL"
    while row = res.fetch_row
      stats["#{row[0]}.oldest"] = row[1].to_i
    end

    report stats
  end

end
