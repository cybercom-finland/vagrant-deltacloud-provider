require 'vagrant-deltacloud-provider/action/abstract_action'
require 'vagrant-deltacloud-provider/client/deltacloud'

module VagrantPlugins
  module Deltacloud
    module Action
      class Suspend < AbstractAction
        def initialize(app, _env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_deltacloud::action::suspend_server')
        end

        def execute(env)
          env[:deltacloud_client] = Deltacloud::DeltacloudClient.instance
          if env[:machine].id
            @logger.info "Saving VM #{env[:machine].id} state and suspending execution..."
            env[:ui].info I18n.t('vagrant.actions.vm.suspend.suspending')
            env[:deltacloud_client].stop_instance(env, env[:machine].id)
          end

          @app.call(env)
        end
      end
    end
  end
end
