require 'log4r'

require 'vagrant-deltacloud-provider/action/abstract_action'

module VagrantPlugins
  module Deltacloud
    module Action
      class StartServer < AbstractAction
        def initialize(app, _env)
          @app    = app
          @logger = Log4r::Logger.new('vagrant_deltacloud::action::start_server')
        end

        def execute(env)
          if env[:machine].id
            env[:ui].info(I18n.t('vagrant_deltacloud.starting_server'))
            env[:deltacloud_client].start_server(env, env[:machine].id)
          end
          @app.call(env)
        end
      end
    end
  end
end
