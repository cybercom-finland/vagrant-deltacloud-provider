module VagrantPlugins
  module Deltacloud
    class Utils
      def initialize
        @logger = Log4r::Logger.new('vagrant_deltacloud::action::config_resolver')
      end
    end
  end
end
