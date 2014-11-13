require 'log4r'
require 'socket'
require 'timeout'
require 'sshkey'

require 'vagrant-deltacloud-provider/config_resolver'
require 'vagrant-deltacloud-provider/utils'
require 'vagrant-deltacloud-provider/action/abstract_action'
require 'vagrant/util/retryable'
require 'vagrant-deltacloud-provider/client/deltacloud'

module VagrantPlugins
  module Deltacloud
    module Action
      class CreateServer < AbstractAction
        include Vagrant::Util::Retryable

        def initialize(app, _env, resolver = ConfigResolver.new, utils = Utils.new)
          @app = app
          @logger = Log4r::Logger.new('vagrant_deltacloud::action::create_server')
          @resolver = resolver
          @utils = utils
        end

        def execute(env)
          @logger.info 'Start create server action'

          options = {
            hardware_profile: @resolver.resolve_hardware_profile(env),
            image: @resolver.resolve_image(env),
            networks: @resolver.resolve_networks(env),
            volumes: @resolver.resolve_volumes(env),
            public_key_name: @resolver.resolve_public_key(env),
            security_groups: @resolver.resolve_security_groups(env),
            user_data: env[:machine].provider_config.user_data,
            metadata: env[:machine].provider_config.metadata
          }

          server_id = create_server(env, options)

          # Store the ID right away so we can track it
          env[:machine].id = server_id
          env[:deltacloud_client] = Deltacloud::DeltacloudClient.instance

          waiting_for_server_to_be_built(env, server_id)
          attach_volumes(env, server_id, options[:volumes]) unless options[:volumes].empty?

          @app.call(env)
        end

        private

        def create_server(env, options)
          config = env[:machine].provider_config
          server_name = config.server_name || env[:machine].name

          env[:ui].info(I18n.t('vagrant_deltacloud.launching_server'))
          env[:ui].info(" -- Tenant             : #{config.tenant_name}")
          env[:ui].info(" -- Name               : #{server_name}")
          env[:ui].info(" -- HardwareProfile    : #{options[:hardware_profile].name}")
          env[:ui].info(" -- HardwareProfileRef : #{options[:hardware_profile].id}")
          unless options[:image].nil?
            env[:ui].info(" -- Image            : #{options[:image].name}")
            env[:ui].info(" -- ImageRef         : #{options[:image].id}")
          end
          env[:ui].info(" -- PublicKey          : #{options[:public_key_name]}")

          log = "Lauching server '#{server_name}' in project '#{config.tenant_name}' "
          log << "with hardware profile '#{options[:hardware_profile].name}' (#{options[:hardware_profile].id}), "
          unless options[:image].nil?
            log << "image '#{options[:image].name}' (#{options[:image].id}) "
          end
          log << "and public key '#{options[:public_key_name]}'"

          @logger.info(log)

          image_id = options[:image].id
          hardware_profile_id = options[:hardware_profile].id
          public_key_name = options[:public_key_name]

          env[:deltacloud_client].launch_instance(env, server_name, image_id, hardware_profile_id, public_key_name)
        end

        def waiting_for_server_to_be_built(env, server_id, retry_interval = 3, timeout = 200)
          @logger.info "Waiting for the server with id #{server_id} to be built..."
          env[:ui].info(I18n.t('vagrant_deltacloud.waiting_for_build'))
          timeout(timeout, Errors::Timeout) do
            server_status = 'WAITING'
            until server_status == 'ACTIVE'
              @logger.debug('Waiting for server to be ACTIVE')
              server_status = env[:deltacloud_client].get_instance_details(env, server_id)['status']
              fail Errors::ServerStatusError, server: server_id if server_status == 'ERROR'
              sleep retry_interval
            end
          end
        end

        def attach_volumes(env, server_id, volumes)
          @logger.info("Attaching volumes #{volumes} to server #{server_id}")
          volumes.each do |volume|
            @logger.debug("Attaching volumes #{volume}")
            env[:deltacloud_client].attach_volume(env, server_id, volume[:id], volume[:device])
          end
        end
      end
    end
  end
end
