require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-deltacloud-provider/client/deltacloud'
require 'vagrant-deltacloud-provider/client/request_logger'
require 'vagrant-deltacloud-provider/action/abstract_action'

module VagrantPlugins
  module Deltacloud
    module Action
      class ConnectDeltacloud < AbstractAction
        include VagrantPlugins::Deltacloud::HttpUtils::RequestLogger

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_deltacloud::action::connect_deltacloud')
          env[:deltacloud_client] = VagrantPlugins::Deltacloud
        end

        def execute(env)
          @app.call(env) unless @app.nil?
        end

        private

        def choose_api_version(service_name, url_property, version_prefix = nil, fail_if_not_found = true)
          versions = yield
          return versions.first['links'].first['href'] unless versions.size > 1
          version_list = ''
          versions.each do |version|
            return version['links'].first['href'] if version['id'].start_with? version_prefix if version_prefix
            links = version['links'].map { |l| l['href'] }
            version_list << "#{version['id'].ljust(6)} #{version['status'].ljust(10)} #{links}\n"
          end
          fail Errors::NoMatchingApiVersion, api_name: service_name, url_property: url_property, version_list: version_list if fail_if_not_found
          nil
        end
      end
    end
  end
end
