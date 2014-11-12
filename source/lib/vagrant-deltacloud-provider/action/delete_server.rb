require 'log4r'

require 'vagrant-deltacloud-provider/action/abstract_action'

module VagrantPlugins
  module Deltacloud
    module Action
      # This deletes the running server, if there is one.
      class DeleteServer < AbstractAction
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_deltacloud::action::delete_server')
        end

        def execute(env)
          env[:deltacloud_client] = Deltacloud::DeltacloudClient.instance
          if env[:machine].id
            @logger.info "Deleting server #{env[:machine].id}..."
            env[:ui].info(I18n.t('vagrant_deltacloud.deleting_server'))
            env[:deltacloud_client].delete_server(env, env[:machine].id)
            env[:deltacloud_client].delete_public_key(env, env[:machine].id)
            env[:machine].id = nil
          end

          @app.call(env)
        end
      end
    end
  end
end
