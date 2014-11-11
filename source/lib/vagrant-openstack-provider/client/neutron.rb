require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-deltacloud-provider/client/http_utils'
require 'vagrant-deltacloud-provider/client/domain'

module VagrantPlugins
  module Deltacloud
    class NeutronClient
      include Singleton
      include VagrantPlugins::Deltacloud::HttpUtils
      include VagrantPlugins::Deltacloud::Domain

      def initialize
        @logger = Log4r::Logger.new('vagrant_deltacloud::neutron')
        @session = VagrantPlugins::Deltacloud.session
      end

      def get_api_version_list(_env)
        json = RestClient.get(@session.endpoints[:network], 'X-Auth-Token' => @session.token, :accept => :json) do |response|
          log_response(response)
          case response.code
          when 200, 300
            response
          when 401
            fail Errors::AuthenticationFailed
          else
            fail Errors::VagrantDeltacloudError, message: response.to_s
          end
        end
        JSON.parse(json)['versions']
      end

      def get_private_networks(env)
        get_networks(env, false)
      end

      def get_all_networks(env)
        get_networks(env, true)
      end

      private

      def get_networks(env, all)
        networks_json = get(env, "#{@session.endpoints[:network]}/networks")
        networks = []
        JSON.parse(networks_json)['networks'].each do |n|
          networks << Item.new(n['id'], n['name']) if all || n['tenant_id'].eql?(@session.project_id)
        end
        networks
      end
    end
  end
end
