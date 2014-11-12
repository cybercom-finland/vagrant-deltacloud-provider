require 'vagrant-deltacloud-provider/command/utils'
require 'vagrant-deltacloud-provider/command/abstract_command'

module VagrantPlugins
  module Deltacloud
    module Command
      class NetworkList < AbstractCommand
        include VagrantPlugins::Deltacloud::Command::Utils

        def self.synopsis
          I18n.t('vagrant_deltacloud.command.network_list_synopsis')
        end
        def cmd(name, argv, env)
          fail Errors::UnrecognizedArgForCommand, cmd: name, arg: argv[1] if argv.size > 1
          networks = env[:deltacloud_client].list_networks(env)
          rows = []
          networks.each do |n|
            rows << [n.id, n.name, n.status, n.address_blocks, n.subnets.map do |s| s.to_s end]
          end
          display_table(env, ['Id', 'Name', 'Status', 'Address blocks', 'Subnets'], rows)
        end
      end
    end
  end
end
