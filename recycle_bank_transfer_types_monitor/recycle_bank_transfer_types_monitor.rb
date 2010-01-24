class RecyclebankMonitorTransferTypes < Scout::Plugin
  needs 'activerecord', 'yaml'
  require 'activerecord'

  class RecycleBankTransfer < ActiveRecord::Base; end

  def build_report
    db_config = YAML::load(File.open(@options['path_to_app'] + '/config/database.yml'))
    ActiveRecord::Base.establish_connection(db_config[@options['rails_env']])

    RecycleBankTransfer.count(:group => :transfer_type).each do |transfer_type, count|
      report "#{transfer_type}.count" => count
    end

    RecycleBankTransfer.sum(:amount, :group => :transfer_type).each do |transfer_type, points|
      report "#{transfer_type}.points" => points
    end
  end
end