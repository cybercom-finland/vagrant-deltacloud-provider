require 'log4r'

require 'vagrant-deltacloud-provider/config_resolver'
require 'vagrant-deltacloud-provider/command/utils'
require 'vagrant-deltacloud-provider/action/abstract_action'
require 'vagrant-deltacloud-provider/client/deltacloud'

module VagrantPlugins
  module Deltacloud
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.

      class ReadSSHInfo < AbstractAction
        include VagrantPlugins::Deltacloud::Command::Utils
        def initialize(app, _env, resolver = ConfigResolver.new)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_deltacloud::action::read_ssh_info')
          @resolver = resolver
        end

        def execute(env)
          @logger.info 'Reading SSH info'
          env[:deltacloud_client] = Deltacloud::DeltacloudClient.instance
          server_id = env[:machine].id.to_sym
          SSHInfoHolder.instance.tap do |holder|
            holder.synchronize do
              holder.ssh_info[server_id] = read_ssh_info(env) if holder.ssh_info[server_id].nil?
              env[:machine_ssh_info] = holder.ssh_info[server_id]
            end
          end
          @app.call(env)
        end

        private

        def read_ssh_info(env)
          config = env[:machine].provider_config
          env[:ui].warn('SSH is disabled in the provider config. The action you are attempting is likely to fail') if config.ssh_disabled
          hash = {
            host: get_ip_address(env),
            port: @resolver.resolve_ssh_port(env),
            username: @resolver.resolve_ssh_username(env)
          }
          hash[:private_key_path] = "#{env[:machine].data_dir}/#{get_public_key_name(env)}" unless config.public_key_name || config.public_key_path
          # Should work silently when https://github.com/mitchellh/vagrant/issues/4637 is fixed
          hash[:log_level] = 'ERROR'
          hash
        end

        def get_public_key_name(env)
          env[:deltacloud_client].get_instance_details(env, env[:machine].id).key_name
        end
      end

      class SSHInfoHolder < Mutex
        include Singleton

        #
        # Keys are machine ids
        #
        attr_accessor :ssh_info

        def initialize
          @ssh_info = {}
        end
      end
    end
  end
end
