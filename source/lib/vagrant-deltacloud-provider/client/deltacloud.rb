require 'log4r'
require 'restclient'
require 'json'
require 'vagrant-deltacloud-provider/client/http_utils'
require 'vagrant-deltacloud-provider/client/domain'

module VagrantPlugins
  module Deltacloud
    class DeltacloudClient
      include Singleton
      include VagrantPlugins::Deltacloud::HttpUtils
      include VagrantPlugins::Deltacloud::Domain

      def initialize
        @logger = Log4r::Logger.new('vagrant_deltacloud::deltacloud')
      end

      def list_public_keys(env)
        key_list = get(env, '/keys')
        JSON.parse(key_list)
      end

      def add_public_key(env, name, public_key)
        response = post(
          env,
          '/keys',
          body: {
            name:       name,
            public_key: public_key
          }
        )
        JSON.parse(response)
      end

      def list_images(env)
        image_list = get(env, '/images')
        JSON.parse(image_list)
      end

      def list_hardware_profiles(env)
        hardware_profile_list = get(env, '/hardware_profiles')
        JSON.parse(hardware_profile_list)['hardware_profiles'].map do |hp|
          HardwareProfile.new(
            hp['id'], hp['name'], hp['properties']['cpu'],
            hp['properties']['memory'], hp['properties']['storage'])
        end
      end

      def list_instances(env)
        instance_list = get(env, '/instances')
        JSON.parse(instance_list)['instances'].map do |i|
          Instance.new(
            i['id'], i['name'])
        end
      end

      def launch_instance(env, name, image_id, size_id, public_key_name)
        response = post(
          env,
          '/instances',
          body: {
            name:     name,
            image_id: image_id,
            hwp_id:   size_id,
            keyname:  public_key_name
          }
        )
        JSON.parse(response)
      end

      def stop_instance(env, instance_id)
        response = post(env, '/instances/' + instance_id + '/stop')
        JSON.parse(response)
      end

      def start_instance(env, instance_id)
        response = post(env, '/instances/' + instance_id + '/start')
        JSON.parse(response)
      end

      def reboot_instance(env, instance_id)
        response = post(env, '/instances/' + instance_id + '/reboot')
        JSON.parse(response)
      end

      def destroy_instance(env, instance_id)
        response = delete(env, '/instances/' + instance_id)
        JSON.parse(response)
      end

      def create_volume(env, volume_name, volume_size_in_gbs)
        response = post(
          env,
          '/storage_volumes',
          body: {
            name:     volume_name,
            capacity: volume_size_in_gbs
          }
        )
        JSON.parse(response)
      end

      def list_volumes(env)
        volume_list = get(env, '/storage_volumes')
        JSON.parse(volume_list)
      end

      def attach_volume(env, volume_id)
        response = post(env, '/storage_volumes/' + volume_id + '/attach')
        JSON.parse(response)
      end

      def volume_info(env, volume_id)
        response = get(env, '/storage_volumes/' + volume_id)
        JSON.parse(response)
      end

      def detach_volume(env, volume_id)
        response = post(env, '/storage_volumes/' + volume_id + '/detach')
        JSON.parse(response)
      end

      def destroy_volume(env, volume_id)
        response = delete(env, '/storage_volumes/' + volume_id)
        JSON.parse(response)
      end

      def create_snapshot(env, instance_id, image_name)
        response = post(
          env,
          '/images',
          body: {
            instance_id: instance_id,
            name:        image_name
          }
        )
        JSON.parse(response)
      end

      def destroy_snapshot(env, image_id)
        response = delete(env, '/images/' + image_id)
        JSON.parse(response)
      end

      def list_networks(env)
        response = get(env, '/networks')
        JSON.parse(response)
      end
    end
  end
end
