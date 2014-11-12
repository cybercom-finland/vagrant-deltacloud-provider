require 'vagrant'
require 'colorize'

module VagrantPlugins
  module Deltacloud
    class Config < Vagrant.plugin('2', :config)
      # The API key to access Deltacloud.
      #
      attr_accessor :password

      # The url to access Deltacloud.
      #
      attr_accessor :deltacloud_api_url

      # The hardware profile of server to launch, either the ID or name. This
      # can also be a regular expression to partially match a name.
      attr_accessor :hardware_profile

      # The name or ID of the image to use. This can also be a regular
      # expression to partially match a name.
      attr_accessor :image

      #
      # The name of the deltacloud project on witch the vm will be created.
      #
      attr_accessor :tenant_name

      # The name of the server. This defaults to the name of the machine
      # defined by Vagrant (via `config.vm.define`), but can be overriden
      # here.
      attr_accessor :server_name

      # The username to access Deltacloud.
      #
      # @return [String]
      attr_accessor :username

      # The name of the public key to use.
      #
      # @return [String]
      attr_accessor :public_key_name

      # The SSH username to use with this Deltacloud instance. This overrides
      # the `config.ssh.username` variable.
      #
      # @return [String]
      attr_accessor :ssh_username

      # The SSH timeout use after server creation. If server startup is too long
      # the timeout value can be increase with this variable. Default is 60 seconds
      #
      # @return [Integer]
      attr_accessor :ssh_timeout

      # Opt files/directories in to the rsync operation performed by this provider
      #
      # @return [Array]
      attr_accessor :rsync_includes

      # Sync folder method. Can be either "rsync" or "none"
      #
      # @return [String]
      attr_accessor :sync_method

      # Network list the VM will be connected to
      #
      # @return [Array]
      attr_accessor :networks

      # Volumes list that will be attached to the VM
      #
      # @return [Array]
      attr_accessor :volumes

      # Public key path to create Deltacloud keypair
      #
      # @return [Array]
      attr_accessor :public_key_path

      # Availability Zone
      #
      # @return [String]
      attr_accessor :availability_zone

      # Pass hints to the Deltacloud scheduler, e.g. { "cell": "some cell name" }
      attr_accessor :scheduler_hints

      # List of strings representing the security groups to apply.
      # e.g. ['ssh', 'http']
      #
      # @return [Array[String]]
      attr_accessor :security_groups

      # User data to be sent to the newly created Deltacloud instance. Use this
      # e.g. to inject a script at boot time.
      #
      # @return [String]
      attr_accessor :user_data

      # A Hash of metadata that will be sent to the instance for configuration
      #
      # @return [Hash]
      attr_accessor :metadata

      # Flag to enable/disable all SSH actions (to use for instance on private networks)
      #
      # @return [Boolean]
      attr_accessor :ssh_disabled

      def initialize
        @password = UNSET_VALUE
        @deltacloud_api_url = UNSET_VALUE
        @hardware_profile = UNSET_VALUE
        @image = UNSET_VALUE
        @tenant_name = UNSET_VALUE
        @server_name = UNSET_VALUE
        @username = UNSET_VALUE
        @rsync_includes = []
        @public_key_name = UNSET_VALUE
        @ssh_username = UNSET_VALUE
        @ssh_timeout = UNSET_VALUE
        @sync_method = UNSET_VALUE
        @availability_zone = UNSET_VALUE
        @networks = []
        @volumes = []
        @public_key_path = UNSET_VALUE
        @scheduler_hints = UNSET_VALUE
        @security_groups = UNSET_VALUE
        @user_data = UNSET_VALUE
        @metadata = UNSET_VALUE
        @ssh_disabled = UNSET_VALUE
      end

      def merge(other)
        result = self.class.new

        # Set all of our instance variables on the new class
        [self, other].each do |obj|
          obj.instance_variables.each do |key|
            # Ignore keys that start with a double underscore. This allows
            # configuration classes to still hold around internal state
            # that isn't propagated.
            next if key.to_s.start_with?('@__')

            # Don't set the value if it is the unset value, either.
            value = obj.instance_variable_get(key)
            print key
            if [:@networks, :@volumes, :@rsync_includes].include? key
              result.instance_variable_set(key, value) unless value.empty?
            else
              result.instance_variable_set(key, value) if value != UNSET_VALUE
            end
          end
        end

        # Persist through the set of invalid methods
        this_invalid  = @__invalid_methods || Set.new
        other_invalid = other.instance_variable_get(:"@__invalid_methods") || Set.new
        result.instance_variable_set(:"@__invalid_methods", this_invalid + other_invalid)

        result
      end

      # rubocop:disable Style/CyclomaticComplexity
      def finalize!
        @password = nil if @password == UNSET_VALUE
        @deltacloud_api_url = nil if @deltacloud_api_url == UNSET_VALUE
        @hardware_profile = nil if @hardware_profile == UNSET_VALUE
        @image = nil if @image == UNSET_VALUE
        @tenant_name = nil if @tenant_name == UNSET_VALUE
        @server_name = nil if @server_name == UNSET_VALUE
        @username = nil if @username == UNSET_VALUE
        @rsync_includes = nil if @rsync_includes.empty?
        @sync_method = 'rsync' if @sync_method == UNSET_VALUE
        @public_key_name = nil if @public_key_name == UNSET_VALUE
        @public_key_path = nil if @public_key_path == UNSET_VALUE
        @availability_zone = nil if @availability_zone == UNSET_VALUE
        @scheduler_hints = nil if @scheduler_hints == UNSET_VALUE
        @security_groups = nil if @security_groups == UNSET_VALUE
        @user_data = nil if @user_data == UNSET_VALUE
        @metadata = nil if @metadata == UNSET_VALUE
        @ssh_disabled = false if @ssh_disabled == UNSET_VALUE

        # The SSH values by default are nil, and the top-level config
        # `config.ssh` values are used.
        @ssh_username = nil if @ssh_username == UNSET_VALUE
        @ssh_timeout = 180 if @ssh_timeout == UNSET_VALUE
        @networks = nil if @networks.empty?
        @volumes = nil if @volumes.empty?
      end
      # rubocop:enable Style/CyclomaticComplexity

      def rsync_include(inc)
        @rsync_includes << inc
      end

      def validate(machine)
        errors = _detected_errors

        errors << I18n.t('vagrant_deltacloud.config.password_required') unless @password
        errors << I18n.t('vagrant_deltacloud.config.username_required') unless @username

        validate_ssh_username(machine, errors)
        validate_ssh_timeout(errors)

        if machine.config.ssh.private_key_path
          puts I18n.t('vagrant_deltacloud.config.public_key_name_required').yellow unless @public_key_name || @public_key_path
        else
          errors << I18n.t('vagrant_deltacloud.config.private_key_missing') if @public_key_name || @public_key_path
        end

        {
          deltacloud_api_url: @deltacloud_api_url
        }.each_pair do |key, value|
          errors << I18n.t('vagrant_deltacloud.config.invalid_uri', key: key, uri: value) unless value.nil? || valid_uri?(value)
        end

        { 'Deltacloud Provider' => errors }
      end

      private

      def validate_ssh_username(machine, errors)
        puts I18n.t('vagrant_deltacloud.config.ssh_username_deprecated').yellow if @ssh_username
        errors << I18n.t('vagrant_deltacloud.config.ssh_username_required') unless @ssh_username || machine.config.ssh.username
      end

      def validate_ssh_timeout(errors)
        return if @ssh_timeout.nil? || @ssh_timeout == UNSET_VALUE
        @ssh_timeout = Integer(@ssh_timeout) if @ssh_timeout.is_a? String
      rescue ArgumentError
        errors << I18n.t('vagrant_deltacloud.config.invalid_value_for_parameter', parameter: 'ssh_timeout', value: @ssh_timeout)
      end

      def valid_uri?(value)
        uri = URI.parse value
        uri.is_a?(URI::HTTP)
      end
    end
  end
end
