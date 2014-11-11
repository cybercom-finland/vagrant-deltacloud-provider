require 'vagrant-deltacloud-provider/command/utils'
require 'vagrant-deltacloud-provider/command/abstract_command'

module VagrantPlugins
  module Deltacloud
    module Command
      class FlavorList < AbstractCommand
        include VagrantPlugins::Deltacloud::Command::Utils

        def self.synopsis
          I18n.t('vagrant_deltacloud.command.flavor_list_synopsis')
        end
        def cmd(name, argv, env)
          fail Errors::NoArgRequiredForCommand, cmd: name unless argv.size == 0
          flavors = env[:deltacloud_client].nova.get_all_flavors(env)

          rows = []
          flavors.each do |f|
            rows << [f.id, f.name, f.vcpus, f.ram, f.disk]
          end
          display_table(env, ['Id', 'Name', 'vCPU', 'RAM (Mo)', 'Disk size (Go)'], rows)
        end
      end
    end
  end
end
