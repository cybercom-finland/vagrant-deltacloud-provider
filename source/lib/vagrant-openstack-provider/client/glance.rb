require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-deltacloud-provider/client/http_utils'
require 'vagrant-deltacloud-provider/client/domain'

module VagrantPlugins
  module Deltacloud
    class GlanceClient
      include Singleton
      include VagrantPlugins::Deltacloud::HttpUtils
      include VagrantPlugins::Deltacloud::Domain

      def initialize
        @logger = Log4r::Logger.new('vagrant_deltacloud::glance')
        @session = VagrantPlugins::Deltacloud.session
      end

      def get_api_version_list(_env)
        json = RestClient.get(@session.endpoints[:image], 'X-Auth-Token' => @session.token, :accept => :json) do |response|
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

      def get_all_images(env)
        images_json = get(env, "#{@session.endpoints[:image]}/images")
        JSON.parse(images_json)['images'].map { |i| Image.new(i['id'], i['name'], i['visibility'], i['size'], i['min_ram'], i['min_disk']) }
      end
    end
  end
end
