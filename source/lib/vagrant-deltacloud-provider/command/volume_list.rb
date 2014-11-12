require 'vagrant-deltacloud-provider/command/utils'
require 'vagrant-deltacloud-provider/command/abstract_command'

module VagrantPlugins
  module Deltacloud
    module Command
      class VolumeList < AbstractCommand
        include VagrantPlugins::Deltacloud::Command::Utils

        def self.synopsis
          I18n.t('vagrant_deltacloud.command.volume_list_synopsis')
        end
        def cmd(name, argv, env)
          fail Errors::NoArgRequiredForCommand, cmd: name unless argv.size == 0
          volumes = env[:deltacloud_client].list_volumes(env)

          rows = []
          volumes.each do |v|
            attachment = "#{v.instance_id} (#{v.device})" unless v.instance_id.nil?
            rows << [v.id, v.name, v.size, v.status, attachment]
          end
          display_table(env, ['Id', 'Name', 'Size (Go)', 'Status', 'Attachment (instance id and device)'], rows)
        end
      end
    end
  end
end
