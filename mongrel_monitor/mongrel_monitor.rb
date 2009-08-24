class MongrelMonitor < Scout::Plugin
  def build_report
    conf_path, status_cmd = @options.values_at( 'mongrel_conf_path', 'mongrel_rails_command' )

    status = `#{status_cmd} cluster::status -C #{conf_path}`
    if status.empty?
      alert "mongrel_rails command: `#{status_cmd}` not found or no status information available"

    else
      report :running => status.scan(/^found mongrel_rails/).size, 
             :down    => status.scan(/^missing mongrel_rails/).size
    end
  end
end
