require 'log4r'

require 'vagrant-deltacloud-provider/action/abstract_action'
require 'vagrant-deltacloud-provider/client/deltacloud'

module VagrantPlugins
  module Deltacloud
    module Action
      # This action reads the state of the machine and puts it in the
      # `:machine_state_id` key in the environment.
      class ReadState < AbstractAction
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_deltacloud::action::read_state')
        end

        def execute(env)
          env[:machine_state_id] = read_state(env)
          env[:deltacloud_client] = Deltacloud::DeltacloudClient.instance
          @app.call(env)
        end

        def read_state(env)
          machine = env[:machine]
          env[:deltacloud_client] = Deltacloud::DeltacloudClient.instance
          return :not_created if machine.id.nil?

          # Find the machine
          server = env[:deltacloud_client].get_instance_details(env, machine.id)
          if server.nil? || server.status == 'DELETED'
            # The machine can't be found
            @logger.info('Machine not found or deleted, assuming it got destroyed.')
            machine.id = nil
            return :not_created
          end

          # Return the state
          server.status.downcase.to_sym
        end
      end
    end
  end
end
