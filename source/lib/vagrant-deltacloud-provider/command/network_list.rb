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
          if argv.size == 0
            networks = env[:deltacloud_client].get_private_networks(env)
          elsif argv[0] == 'all'
            networks = env[:deltacloud_client].list_networks(env)
          else
            fail Errors::UnrecognizedArgForCommand, cmd: name, arg: argv[0]
          end
          display_item_list(env, networks)
        end
      end
    end
  end
end
