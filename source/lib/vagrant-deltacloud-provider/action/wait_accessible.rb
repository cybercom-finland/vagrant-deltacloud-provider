require 'log4r'
require 'vagrant-deltacloud-provider/command/utils'
require 'vagrant-deltacloud-provider/client/deltacloud'

module VagrantPlugins
  module Deltacloud
    module Action
      class WaitForServerToBeAccessible < AbstractAction
        include VagrantPlugins::Deltacloud::Command::Utils
        def initialize(app, env, resolver = nil, ssh = nil)
          @logger   = Log4r::Logger.new('vagrant_deltacloud::action::wait_accessible')
          @app      = app
          @ssh      = ssh || Vagrant::Action::Builtin::SSHRun.new(app, env)
          @resolver = resolver || VagrantPlugins::Deltacloud::ConfigResolver.new
        end

        def execute(env)
          env[:deltacloud_client] = Deltacloud::DeltacloudClient.instance
          waiting_for_server_to_be_reachable(env)
          @logger.info 'The server is ready'
          env[:ui].info(I18n.t('vagrant_deltacloud.ready'))
          @app.call(env)
        end

        private

        def waiting_for_server_to_be_reachable(env)
          return if env[:interrupted]
          ssh_timeout = env[:machine].provider_config.ssh_timeout
          return if server_is_reachable?(env, ssh_timeout)
          env[:ui].error(I18n.t('vagrant_deltacloud.timeout'))
          fail Errors::SshUnavailable, host: get_ip_address(env), timeout: ssh_timeout
        end

        def server_is_reachable?(env, timeout)
          start_time = Time.now
          current_time = start_time
          nb_retry = 0

          while (current_time - start_time) <= timeout
            @logger.debug "Checking if SSH port is open... Attempt number #{nb_retry}"
            if nb_retry % 5 == 0
              @logger.info 'Waiting for SSH to become available...'
              env[:ui].info(I18n.t('vagrant_deltacloud.waiting_for_ssh'))
            end

            env[:ssh_run_command] = 'exit 0'
            env[:ssh_opts] = {
              extra_args: ['-o', 'BatchMode=yes']
            }
            @ssh.call(env)
            return true if env[:ssh_run_exit_status] == 0

            @logger.debug 'SSH not yet available... new retry in in 1 second'
            nb_retry += 1
            sleep 1
            current_time = Time.now
          end

          false
        end
      end
    end
  end
end
