require 'vagrant-deltacloud-provider/command/utils'
require 'vagrant-deltacloud-provider/command/abstract_command'

module VagrantPlugins
  module Deltacloud
    module Command
      class HardwareProfileList < AbstractCommand
        include VagrantPlugins::Deltacloud::Command::Utils

        def self.synopsis
          I18n.t('vagrant_deltacloud.command.hardware_profile_list_synopsis')
        end
        def cmd(name, argv, env)
          fail Errors::NoArgRequiredForCommand, cmd: name unless argv.size == 0
          hardware_profiles = env[:deltacloud_client].list_hardware_profiles(env)

          rows = []
          @logger.info 'hardware_profiles received: ' + hardware_profiles
          hardware_profiles.each do |h|
            rows << [h.id, h.name, h.vcpus, h.ram, h.disk]
          end
          display_table(env, ['Id', 'Name', 'vCPU', 'RAM (Mo)', 'Disk size (Go)'], rows)
        end
      end
    end
  end
end
