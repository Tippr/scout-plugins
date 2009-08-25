class PollerMonitor < Scout::Plugin
  def build_report
    stats = {}

    # monitor poller process count
    name, total = @options.values_at( 'poller_name', 'poller_total' )
    running = `pgrep -f #{name}`.split("\n").size
    stats.update 'running' => running,
                 'stopped' => [total-running, 0].max

    # monitor new craigslist posts
#    require "#{@options['path_to_app']}/config/environment"
#    last_run = memory(:last_run) || 1.hour.ago
#    stats['new_listings'] = Listing.count( :conditions => ['datasource_type_id = ? AND created_at > ?', DataSourceType[:craigslist].id, last_run] )
#    remember :last_run => Time.now

    report stats
  end
end
