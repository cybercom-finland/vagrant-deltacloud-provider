require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-deltacloud-provider/client/keystone'
require 'vagrant-deltacloud-provider/client/nova'
require 'vagrant-deltacloud-provider/client/neutron'
require 'vagrant-deltacloud-provider/client/cinder'
require 'vagrant-deltacloud-provider/client/glance'

module VagrantPlugins
  module Deltacloud
    class Session
      include Singleton

      attr_accessor :token
      attr_accessor :project_id
      attr_accessor :endpoints

      def initialize
        @token = nil
        @project_id = nil
        @endpoints = {}
      end

      def reset
        initialize
      end
    end

    def self.session
      Session.instance
    end

    def self.keystone
      Deltacloud::KeystoneClient.instance
    end

    def self.nova
      Deltacloud::NovaClient.instance
    end

    def self.neutron
      Deltacloud::NeutronClient.instance
    end

    def self.cinder
      Deltacloud::CinderClient.instance
    end

    def self.glance
      Deltacloud::GlanceClient.instance
    end
  end
end
