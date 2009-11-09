require 'rubygems'

class CraigslistReplyMonitor < Scout::Plugin

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

    res = nil
    age = begin
      res = mysql.query  "SELECT TIME_TO_SEC( TIMEDIFF(UTC_TIMESTAMP, conversation_messages.created_at) ) / (60.0 * 60.0) AS hours_since_last_cl_reply
                            FROM conversation_messages
                            JOIN email_addresses ON email_addresses.id = conversation_messages.real_from_address_id
                            JOIN conversations   ON conversations.id   = conversation_messages.conversation_id
                            JOIN listings        ON listings.id        = conversations.listing_id
                            JOIN datasources     ON datasources.id     = listings.datasource_id
                           WHERE datasources.datasource_type_id = 1                   /* 1 = Craigslist */
                             AND conversations.owner_role = 'taker'                   /* means the conversation was started by a KL member using 'contact giver' */
                             AND conversation_messages.direction = 'to_owner'         /* only consider replies */
                             AND email_addresses.address NOT LIKE '%@craigslist.org'  /* ignore Craigslist bounce messages */
                        ORDER BY conversation_messages.id DESC
                           LIMIT 1"
      res.fetch_row.first.to_f
    ensure
      res.free if res.respond_to?(:free)
    end

    report({ :craigslist_reply_age => age }) if age
  end

end
