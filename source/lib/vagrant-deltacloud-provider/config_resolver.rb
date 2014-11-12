module VagrantPlugins
  module Deltacloud
    class ConfigResolver
      def initialize
        @logger = Log4r::Logger.new('vagrant_deltacloud::action::config_resolver')
      end

      def resolve_ssh_port(env)
        machine_config = env[:machine].config
        return machine_config.ssh.port if machine_config.ssh.port
        22
      end

      def resolve_hardware_profile(env)
        @logger.info 'Resolving hardware profile'
        config = env[:machine].provider_config
        deltacloud = env[:deltacloud_client].deltacloud
        env[:ui].info(I18n.t('vagrant_deltacloud.finding_hardware_profile'))
        hardware_profiles = deltacloud.list_hardware_profiles(env)
        @logger.info "Finding hardware profile matching name '#{config.hardware_profile}'"
        hardware_profile = find_matching(hardware_profiles, config.hardware_profile)
        fail Errors::NoMatchingHardwareProfile unless hardware_profile
        hardware_profile
      end

      def resolve_image(env)
        @logger.info 'Resolving image'
        config = env[:machine].provider_config
        return nil if config.image.nil?
        deltacloud = env[:deltacloud_client].deltacloud
        env[:ui].info(I18n.t('vagrant_deltacloud.finding_image'))
        images = deltacloud.list_images(env)
        @logger.info "Finding image matching name '#{config.image}'"
        image = find_matching(images, config.image)
        fail Errors::NoMatchingImage unless image
        image
      end

      def resolve_public_key(env)
        config = env[:machine].provider_config
        deltacloud = env[:deltacloud_client].deltacloud
        return config.public_key_name if config.public_key_name
        return deltacloud.import_public_key_from_file(env, config.public_key_path) if config.public_key_path
        generate_keypair(env)
      end

      def resolve_networks(env)
        @logger.info 'Resolving network(s)'
        config = env[:machine].provider_config
        return [] if config.networks.nil? || config.networks.empty?
        env[:ui].info(I18n.t('vagrant_deltacloud.finding_networks'))
        all_networks = env[:deltacloud_client].deltacloud.get_all_networks(env)
        all_network_ids = all_networks.map { |v| v.id }

        networks = []
        config.networks.each do |network|
          networks << resolve_network(network, all_networks, all_network_ids)
        end
        @logger.debug("Resolved networks : #{networks.to_json}")
        networks
      end

      def resolve_volumes(env)
        @logger.info 'Resolving volume(s)'
        config = env[:machine].provider_config
        return [] if config.volumes.nil? || config.volumes.empty?
        env[:ui].info(I18n.t('vagrant_deltacloud.finding_volumes'))
        resolve_volumes_without_volume_service(env)
      end

      def resolve_ssh_username(env)
        config = env[:machine].provider_config
        machine_config = env[:machine].config
        return machine_config.ssh.username if machine_config.ssh.username
        return config.ssh_username if config.ssh_username
        fail Errors::NoMatchingSshUsername
      end

      def resolve_security_groups(env)
        groups = []
        env[:machine].provider_config.security_groups.each do |group|
          case group
          when String
            groups << { name: group }
          when Hash
            groups << group
          end
        end unless env[:machine].provider_config.security_groups.nil?
        groups
      end

      private

      def generate_keypair(env)
        key = SSHKey.generate
        deltacloud = env[:deltacloud_client].deltacloud
        generated_keyname = 'vagrant_key_' + SecureRandom.uuid;
        deltacloud.add_public_key(env, generated_keyname, key.ssh_public_key)
        file_path = "#{env[:machine].data_dir}/#{generated_keyname}"
        File.write(file_path, key.private_key)
        File.chmod(0600, file_path)
        generated_keyname
      end

      def resolve_networks_without_network_service(env)
        config = env[:machine].provider_config
        networks = []
        config.networks.each do |network|
          case network
          when String
            env[:ui].info(I18n.t('vagrant_deltacloud.warn_network_identifier_is_assumed_to_be_an_id', network: network))
            networks << { uuid: network }
          when Hash
            fail Errors::ConflictNetworkNameId, network: network if network.key?(:name) && network.key?(:id)
            fail Errors::NetworkServiceUnavailable if network.key? :name
            if network.key?(:address)
              networks << { uuid: network[:id], fixed_ip: network[:address] }
            else
              networks << { uuid: network[:id] }
            end
          end
        end
        networks
      end

      def resolve_network(network, network_list, network_ids)
        return resolve_network_from_string(network, network_list) if network.is_a? String
        return resolve_network_from_hash(network, network_list, network_ids) if network.is_a? Hash
        fail Errors::InvalidNetworkObject, network: network
      end

      def resolve_network_from_string(network, network_list)
        found_network = find_matching(network_list, network)
        fail Errors::UnresolvedNetwork, network: network if found_network.nil?
        { uuid: found_network.id }
      end

      def resolve_network_from_hash(network, network_list, network_ids)
        if network.key?(:id)
          fail Errors::ConflictNetworkNameId, network: network if network.key?(:name)
          network_id = network[:id]
          fail Errors::UnresolvedNetworkId, id: network_id unless network_ids.include? network_id
        elsif network.key?(:name)
          network_list.each do |v|
            next unless v.name.eql? network[:name]
            fail Errors::MultipleNetworkName, name: network[:name] unless network_id.nil?
            network_id = v.id
          end
          fail Errors::UnresolvedNetworkName, name: network[:name] unless network_ids.include? network_id
        else
          fail Errors::ConflictNetworkNameId, network: network
        end
        return { uuid: network_id, fixed_ip: network[:address] } if network.key?(:address)
        { uuid: network_id }
      end

      def resolve_volumes_without_volume_service(env)
        env[:machine].provider_config.volumes.map { |volume| resolve_volume_without_volume_service(env, volume) }
      end

      def resolve_volume_without_volume_service(env, volume, default_device = nil)
        case volume
        when String
          env[:ui].info(I18n.t('vagrant_deltacloud.warn_volume_identifier_is_assumed_to_be_an_id', volume: volume))
          return { id: volume, device: default_device }
        when Hash
          fail Errors::ConflictVolumeNameId, volume: volume if volume.key?(:name) && volume.key?(:id)
          fail Errors::VolumeServiceUnavailable if volume.key? :name
          return { id: volume[:id], device: volume[:device] || default_device }
        end
        fail Errors::InvalidVolumeObject, volume: volume
      end

      def resolve_volume(volume, volume_list, volume_ids)
        return resolve_volume_from_string(volume, volume_list) if volume.is_a? String
        return resolve_volume_from_hash(volume, volume_list, volume_ids) if volume.is_a? Hash
        fail Errors::InvalidVolumeObject, volume: volume
      end

      def resolve_volume_from_string(volume, volume_list)
        found_volume = find_matching(volume_list, volume)
        fail Errors::UnresolvedVolume, volume: volume if found_volume.nil?
        { id: found_volume.id, device: nil }
      end

      def resolve_volume_from_hash(volume, volume_list, volume_ids)
        device = nil
        device = volume[:device] if volume.key?(:device)
        if volume.key?(:id)
          fail Errors::ConflictVolumeNameId, volume: volume if volume.key?(:name)
          volume_id = volume[:id]
          fail Errors::UnresolvedVolumeId, id: volume_id unless volume_ids.include? volume_id
        elsif volume.key?(:name)
          volume_list.each do |v|
            next unless v.name.eql? volume[:name]
            fail Errors::MultipleVolumeName, name: volume[:name] unless volume_id.nil?
            volume_id = v.id
          end
          fail Errors::UnresolvedVolumeName, name: volume[:name] unless volume_ids.include? volume_id
        else
          fail Errors::ConflictVolumeNameId, volume: volume
        end
        { id: volume_id, device: device }
      end

      # This method finds a matching _thing_ in a collection of
      # _things_. This works matching if the ID or NAME equals to
      # `name`. Or, if `name` is a regexp, a partial match is chosen
      # as well.
      def find_matching(collection, name)
        collection.each do |single|
          return single if single.id == name
          return single if single.name == name
          return single if name.is_a?(Regexp) && name =~ single.name
        end
        @logger.error "Element '#{name}' not found in collection #{collection}"
        nil
      end
    end
  end
end
