require 'vagrant-deltacloud-provider/command/utils'
require 'vagrant-deltacloud-provider/command/abstract_command'

module VagrantPlugins
  module Deltacloud
    module Command
      class ImageList < AbstractCommand
        include VagrantPlugins::Deltacloud::Command::Utils

        def self.synopsis
          I18n.t('vagrant_deltacloud.command.image_list_synopsis')
        end
        def cmd(name, argv, env)
          fail Errors::NoArgRequiredForCommand, cmd: name unless argv.size == 0
          rows = []
          headers = %w(Id Name)
          images = env[:deltacloud_client].get_all_images(env)
          images.each { |image| rows << [image.id, image.name] }
          display_table(env, headers, rows)
        end
      end
    end
  end
end
