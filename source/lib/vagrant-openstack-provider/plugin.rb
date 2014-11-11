begin
  require 'vagrant'
rescue LoadError
  raise 'The Deltacloud Cloud provider must be run within Vagrant.'
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < '1.4.0'
  fail 'Deltacloud Cloud provider is only compatible with Vagrant 1.4+'
end

module VagrantPlugins
  module Deltacloud
    class Plugin < Vagrant.plugin('2')
      name 'Deltacloud Cloud'
      description <<-DESC
      This plugin enables Vagrant to manage machines in Deltacloud Cloud.
      DESC

      config(:deltacloud, :provider) do
        require_relative 'config'
        Config
      end

      provider(:deltacloud, box_optional: true) do
        # Setup some things
        Deltacloud.init_i18n
        Deltacloud.init_logging

        # Load the actual provider
        require_relative 'provider'
        Provider
      end

      command('deltacloud') do
        require_relative 'command/main'
        Command::Main
      end
    end
  end
end
