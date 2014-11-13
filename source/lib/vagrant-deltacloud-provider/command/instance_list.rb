require 'vagrant-deltacloud-provider/command/utils'
require 'vagrant-deltacloud-provider/command/abstract_command'

module VagrantPlugins
  module Deltacloud
    module Command
      class InstanceList < AbstractCommand
        include VagrantPlugins::Deltacloud::Command::Utils

        def self.synopsis
          I18n.t('vagrant_deltacloud.command.instance_list_synopsis')
        end
        def cmd(name, argv, env)
          fail Errors::NoArgRequiredForCommand, cmd: name unless argv.size == 0
          rows = []
          headers = %w(Id Name Status Key_name)
          images = env[:deltacloud_client].list_instances(env)
          images.each { |instance| rows << [instance.id, instance.name, instance.status, instance.key_name] }
          display_table(env, headers, rows)
        end
      end
    end
  end
end
