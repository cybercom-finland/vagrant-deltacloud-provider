require 'log4r'
require 'timeout'

require 'vagrant-deltacloud-provider/action/abstract_action'
require 'vagrant-deltacloud-provider/client/deltacloud'

module VagrantPlugins
  module Deltacloud
    module Action
      class WaitForServerToBeActive < AbstractAction
        def initialize(app, _env, retry_interval = 3, timeout = 200)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_deltacloud::action::start_server')
          @retry_interval = retry_interval
          @timeout = timeout
        end

        def execute(env)
          env[:deltacloud_client] = Deltacloud::DeltacloudClient.instance
          if env[:machine].id
            env[:ui].info(I18n.t('vagrant_deltacloud.waiting_start'))
            client = env[:deltacloud_client]
            timeout(@timeout, Errors::Timeout) do
              while client.get_server_details(env, env[:machine].id)['status'] != 'ACTIVE'
                sleep @retry_interval
                @logger.info('Waiting for server to be active')
              end
            end
          end
          @app.call(env)
        end
      end
    end
  end
end
