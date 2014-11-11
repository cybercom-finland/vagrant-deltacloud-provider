require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-deltacloud-provider/client/keystone'
require 'vagrant-deltacloud-provider/client/request_logger'

module VagrantPlugins
  module Deltacloud
    module HttpUtils
      include VagrantPlugins::Deltacloud::HttpUtils::RequestLogger

      def get(env, url, headers = {})
        calling_method = caller[0][/`.*'/][1..-2]
        @logger.debug("#{calling_method} - start")

        headers.merge!('X-Auth-Token' => @session.token, :accept => :json)

        log_request(:GET, url, headers)

        authenticated(env) do
          RestClient.get(url, headers) { |res| handle_response(res) }.tap do
            @logger.debug("#{calling_method} - end")
          end
        end
      end

      def post(env, url, body = nil, headers = {})
        calling_method = caller[0][/`.*'/][1..-2]
        @logger.debug("#{calling_method} - start")

        headers.merge!('X-Auth-Token' => @session.token, :accept => :json, :content_type => :json)

        log_request(:POST, url, body, headers)

        authenticated(env) do
          RestClient.post(url, body, headers) { |res| handle_response(res) }.tap do
            @logger.debug("#{calling_method} - end")
          end
        end
      end

      def delete(env, url, headers = {})
        calling_method = caller[0][/`.*'/][1..-2]
        @logger.debug("#{calling_method} - start")

        headers.merge!('X-Auth-Token' => @session.token, :accept => :json, :content_type => :json)

        log_request(:DELETE, url, headers)

        authenticated(env) do
          RestClient.delete(url, headers) { |res| handle_response(res) }.tap do
            @logger.debug("#{calling_method} - end")
          end
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

      def authenticated(env)
        nb_retry = 0
        begin
          return yield
        rescue Errors::AuthenticationRequired => e
          nb_retry += 1
          env[:ui].warn(e)
          env[:ui].warn(I18n.t('vagrant_deltacloud.trying_authentication'))
          env[:deltacloud_client].keystone.authenticate(env)
          retry if nb_retry < 3
          raise e
        end
      end
    end
  end
end
