require 'log4r'

require 'vagrant-deltacloud-provider/action/abstract_action'
require 'vagrant-deltacloud-provider/client/deltacloud'

module VagrantPlugins
  module Deltacloud
    module Action
      class StopServer < AbstractAction
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_deltacloud::action::stop_server')
        end

        def execute(env)
          env[:deltacloud_client] = Deltacloud::DeltacloudClient.instance
          if env[:machine].id
            @logger.info "Stopping server #{env[:machine].id}..."
            env[:ui].info(I18n.t('vagrant_deltacloud.stopping_server'))
            env[:deltacloud_client].stop_instance(env, env[:machine].id)
          end
          @app.call(env)
        end
      end
    end
  end
end
