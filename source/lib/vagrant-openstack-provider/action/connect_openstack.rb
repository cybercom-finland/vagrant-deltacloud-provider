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
          client = env[:deltacloud_client]
          if client.session.token.nil?
            catalog = client.keystone.authenticate(env)
            read_endpoint_catalog(env, catalog)
            override_endpoint_catalog_with_user_config(env)
            log_endpoint_catalog(env)
          end
          @app.call(env) unless @app.nil?
        end

        private

        def read_endpoint_catalog(env, catalog)
          config = env[:machine].provider_config
          client = env[:deltacloud_client]
          @logger.info(I18n.t('vagrant_deltacloud.client.looking_for_available_endpoints'))

          catalog.each do |service|
            se = service['endpoints']
            if se.size > 1
              env[:ui].warn I18n.t('vagrant_deltacloud.client.multiple_endpoint', size: se.size, type: service['type'])
              env[:ui].warn "  => #{service['endpoints'][0]['publicURL']}"
            end
            url = se[0]['publicURL'].strip
            client.session.endpoints[service['type'].to_sym] = url unless url.empty?
          end

          client.session.endpoints[:network] = choose_api_version('Neutron', 'deltacloud_api_url', 'v2') do
            client.neutron.get_api_version_list(env)
          end if config.deltacloud_api_url.nil? && !client.session.endpoints[:network].nil?
        end

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

        def override_endpoint_catalog_with_user_config(env)
          client = env[:deltacloud_client]
          config = env[:machine].provider_config
          client.session.endpoints[:api] = config.deltacloud_api_url unless config.deltacloud_api_url.nil?
          client.session.endpoints.delete_if { |_, value| value.nil? || value.empty? }
        end

        def log_endpoint_catalog(env)
          env[:deltacloud_client].session.endpoints.each do |key, value|
            @logger.info(" -- #{key.to_s.ljust 15}: #{value}")
          end
        end
      end
    end
  end
end
