require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-deltacloud-provider/client/request_logger'

module VagrantPlugins
  module Deltacloud
    module HttpUtils
      include VagrantPlugins::Deltacloud::HttpUtils::RequestLogger

      def get(env, url, headers = {})
        config = env[:machine].provider_config
        calling_method = caller[0][/`.*'/][1..-2]
        @logger.debug("#{calling_method} - start")

        headers.merge!(accept: 'json', content_type: 'json')

        url = config.deltacloud_api_url + url +
          '?format=json'

        resource = RestClient::Resource.new(
          url,
          config.username + '+' + config.tenant_name,
          config.password)

        log_request(:GET, url, headers)

        resource.get(headers: headers) { |res| handle_response(res) }.tap do
          @logger.debug("#{calling_method} - end")
        end
      end

      def post(env, url, body = nil, headers = {})
        config = env[:machine].provider_config
        calling_method = caller[0][/`.*'/][1..-2]
        @logger.debug("#{calling_method} - start")

        headers.merge!(accept: 'json', content_type: 'json')

        url = config.deltacloud_api_url + url +
          '?format=json'

        resource = RestClient::Resource.new(
          url,
          config.username + '+' + config.tenant_name,
          config.password)

        log_request(:POST, url, body, headers)

        resource.post(
          body: body,
          headers: headers) { |res| handle_response(res) }.tap do
          @logger.debug("#{calling_method} - end")
        end
      end

      def delete(env, url, headers = {})
        config = env[:machine].provider_config
        calling_method = caller[0][/`.*'/][1..-2]
        @logger.debug("#{calling_method} - start")

        headers.merge!(accept: 'json', content_type: 'json')

        url = config.deltacloud_api_url + url +
          '?format=json'

        resource = RestClient::Resource.new(
          url,
          config.username + '+' + config.tenant_name,
          config.password)
        log_request(:DELETE, url, headers)

        resource.delete(headers: headers) { |res| handle_response(res) }.tap do
          @logger.debug("#{calling_method} - end")
        end
      end

      private

      ERRORS =
          {
            '400' => 'badRequest',
            '404' => 'itemNotFound',
            '409' => 'conflictingRequest'
          }

      def handle_response(response)
        log_response(response)
        case response.code
        when 200, 201, 202, 204
          response
        when 401
          fail Errors::AuthenticationRequired
        when 400, 404, 409
          message = JSON.parse(response.to_s)[ERRORS[response.code.to_s]]['message']
          fail Errors::VagrantDeltacloudError, message: message, code: response.code
        else
          fail Errors::VagrantDeltacloudError, message: response.to_s, code: response.code
        end
      end
    end
  end
end
