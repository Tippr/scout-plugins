class PollerMonitor < Scout::Plugin
  def build_report
    stats = {}

    # monitor poller process count
    poller_name = @options['poller_name'] || 'poller_scheduler'
    stats['pollers'] = `pgrep -f #{poller_name}`.split("\n").size

    # monitor new craigslist posts
#    require "#{@options['path_to_app']}/config/environment"
#    last_run = memory(:last_run) || 1.hour.ago
#    stats['new_listings.craigslist'] = Listing.count( :conditions => ['datasource_type_id = ? AND created_at > ?', DataSourceType[:craigslist].id, last_run] )
#    remember :last_run => Time.now

    report stats
  end
end
