require 'vagrant-deltacloud-provider/action/abstract_action'
require 'vagrant-deltacloud-provider/client/deltacloud'

module VagrantPlugins
  module Deltacloud
    module Action
      class Resume < AbstractAction
        def initialize(app, _env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_deltacloud::action::resume_server')
        end

        def execute(env)
          env[:deltacloud_client] = Deltacloud::DeltacloudClient.instance
          if env[:machine].id
            @logger.info "Resuming suspended VM #{env[:machine].id}..."
            env[:ui].info I18n.t('vagrant.actions.vm.resume.resuming')
            env[:deltacloud_client].start_instance(env, env[:machine].id)
          end

          @app.call(env)
        end
      end
    end
  end
end
