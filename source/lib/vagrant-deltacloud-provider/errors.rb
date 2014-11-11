require 'vagrant'

module VagrantPlugins
  module Deltacloud
    module Errors
      class VagrantDeltacloudError < Vagrant::Errors::VagrantError
        error_namespace('vagrant_deltacloud.errors')
        error_key(:default)
      end

      class Timeout < VagrantDeltacloudError
        error_key(:timeout)
      end

      class AuthenticationRequired < VagrantDeltacloudError
        error_key(:authentication_required)
      end

      class AuthenticationFailed < VagrantDeltacloudError
        error_key(:authentication_failed)
      end

      class BadAuthenticationEndpoint < VagrantDeltacloudError
        error_key(:bad_authentication_endpoint)
      end

      class NoMatchingApiVersion < VagrantDeltacloudError
        error_key(:no_matching_api_version)
      end

      class CreateBadState < VagrantDeltacloudError
        error_key(:create_bad_state)
      end

      class NoMatchingFlavor < VagrantDeltacloudError
        error_key(:no_matching_flavor)
      end

      class NoMatchingImage < VagrantDeltacloudError
        error_key(:no_matching_image)
      end

      class SyncMethodError < VagrantDeltacloudError
        error_key(:sync_method_error)
      end

      class RsyncError < VagrantDeltacloudError
        error_key(:rsync_error)
      end

      class SshUnavailable < VagrantDeltacloudError
        error_key(:ssh_unavailble)
      end

      class NoArgRequiredForCommand < VagrantDeltacloudError
        error_key(:no_arg_required_for_command)
      end

      class UnrecognizedArgForCommand < VagrantDeltacloudError
        error_key(:unrecognized_arg_for_command)
      end

      class UnableToResolveFloatingIP < VagrantDeltacloudError
        error_key(:unable_to_resolve_floating_ip)
      end

      class UnableToResolveIP < VagrantDeltacloudError
        error_key(:unable_to_resolve_ip)
      end

      class UnableToResolveSSHKey < VagrantDeltacloudError
        error_key(:unable_to_resolve_ssh_key)
      end

      class InvalidNetworkObject < VagrantDeltacloudError
        error_key(:invalid_network_format)
      end

      class UnresolvedNetwork < VagrantDeltacloudError
        error_key(:unresolved_network)
      end

      class UnresolvedNetworkId < VagrantDeltacloudError
        error_key(:unresolved_network_id)
      end

      class UnresolvedNetworkName < VagrantDeltacloudError
        error_key(:unresolved_network_name)
      end

      class ConflictNetworkNameId < VagrantDeltacloudError
        error_key(:conflict_network_name_id)
      end

      class MultipleNetworkName < VagrantDeltacloudError
        error_key(:multiple_network_name)
      end

      class InvalidVolumeObject < VagrantDeltacloudError
        error_key(:invalid_volume_format)
      end

      class UnresolvedVolume < VagrantDeltacloudError
        error_key(:unresolved_volume)
      end

      class UnresolvedVolumeId < VagrantDeltacloudError
        error_key(:unresolved_volume_id)
      end

      class UnresolvedVolumeName < VagrantDeltacloudError
        error_key(:unresolved_volume_name)
      end

      class ConflictVolumeNameId < VagrantDeltacloudError
        error_key(:conflict_volume_name_id)
      end

      class MultipleVolumeName < VagrantDeltacloudError
        error_key(:multiple_volume_name)
      end

      class MissingBootOption < VagrantDeltacloudError
        error_key(:missing_boot_option)
      end

      class NoMatchingSshUsername < VagrantDeltacloudError
        error_key(:ssh_username_missing)
      end

      class InstanceNotFound < VagrantDeltacloudError
        error_key(:instance_not_found)
      end

      class NetworkServiceUnavailable < VagrantDeltacloudError
        error_key(:nerwork_service_unavailable)
      end

      class VolumeServiceUnavailable < VagrantDeltacloudError
        error_key(:volume_service_unavailable)
      end

      class FloatingIPAlreadyAssigned < VagrantDeltacloudError
        error_key(:floating_ip_already_assigned)
      end

      class FloatingIPNotAvailable < VagrantDeltacloudError
        error_key(:floating_ip_not_available)
      end

      class ServerStatusError < VagrantDeltacloudError
        error_key(:server_status_error)
      end
    end
  end
end
