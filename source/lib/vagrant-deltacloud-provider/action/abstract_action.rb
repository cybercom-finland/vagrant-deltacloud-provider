require 'colorize'

module VagrantPlugins
  module Deltacloud
    module Action
      class AbstractAction
        def call(env)
          execute(env)
        # rubocop:disable Style/SpecialGlobalVars
        # rubocop:disable Lint/RescueException
        rescue Errors::VagrantDeltacloudError => e
          raise e
        rescue Exception => e
          puts I18n.t('vagrant_deltacloud.global_error') unless e.message && e.message.start_with?('Catched Error:')
          raise $!, "Catched Error: #{$!}", $!.backtrace
        end
        # rubocop:enable Lint/RescueException
        # rubocop:enable Style/SpecialGlobalVars
      end
    end
  end
end
