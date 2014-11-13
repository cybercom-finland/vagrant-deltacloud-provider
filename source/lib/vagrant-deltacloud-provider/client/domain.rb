require 'log4r'
require 'restclient'
require 'json'

module VagrantPlugins
  module Deltacloud
    module Domain
      class Item
        attr_accessor :id, :name
        def initialize(id, name)
          @id = id
          @name = name
        end

        def ==(other)
          other.class == self.class && other.state == state
        end

        def state
          [@id, @name]
        end
      end

      class Instance < Item
        attr_accessor :status
        attr_accessor :key_name

        def initialize(id, name, status = nil, key_name = nil)
          @status = status
          @key_name = key_name
          super(id, name)
        end

        protected

        def state
          [@id, @name, @status, @key_name]
        end
      end

      class Image < Item
        attr_accessor :visibility
        attr_accessor :size
        attr_accessor :min_ram
        attr_accessor :min_disk

        def initialize(id, name, visibility = nil, size = nil, min_ram = nil, min_disk = nil)
          @visibility = visibility
          @size = size
          @min_ram = min_ram
          @min_disk = min_disk
          super(id, name)
        end

        protected

        def state
          [@id, @name, @visibility, @size, @min_ram, @min_disk]
        end
      end

      class HardwareProfile < Item
        #
        # The number of vCPU
        #
        attr_accessor :vcpus

        #
        # The amount of RAM in Megaoctet
        #
        attr_accessor :ram

        #
        # The size of root disk in Gigaoctet
        #
        attr_accessor :disk

        def initialize(id, name, vcpus, ram, disk)
          @vcpus = vcpus
          @ram  = ram
          @disk = disk
          super(id, name)
        end

        protected

        def state
          [@id, @name, @vcpus, @ram, @disk]
        end
      end

      class Volume < Item
        #
        # Size in Gigaoctet
        #
        attr_accessor :size

        #
        # Status (e.g. 'Available', 'In-use')
        #
        attr_accessor :status

        #
        # Whether volume is bootable or not
        #
        attr_accessor :bootable

        #
        # instance id volume is attached to
        #
        attr_accessor :instance_id

        #
        # device (e.g. /dev/sdb) if attached
        #
        attr_accessor :device

        # rubocop:disable Style/ParameterLists
        def initialize(id, name, size, status, bootable, instance_id, device)
          @size = size
          @status = status
          @bootable = bootable
          @instance_id = instance_id
          @device = device
          super(id, name)
        end
        # rubocop:enable Style/ParameterLists

        def to_s
          {
            id: @id,
            name: @name,
            size: @size,
            status: @status,
            bootable: @bootable,
            instance_id: @instance_id,
            device: @device
          }.to_json
        end

        protected

        def state
          [@id, @name, @size, @status, @bootable, @instance_id, @device]
        end
      end

      class Network < Item
        attr_accessor :status
        attr_accessor :address_blocks
        attr_accessor :subnets

        def initialize(id, name, status, address_blocks, subnets)
          @status = status
          @address_blocks = address_blocks
          @subnets = subnets
          super(id, name)
        end

        protected

        def state
          [@id, @name, @status, @address_blocks, @subnets]
        end
      end

      class Subnet < Item
        def initialize(id, name)
          super(id, name)
        end

        def to_s
          {
            id: @id,
            name: @name
          }.to_json
        end

        protected

        def state
          [@id, @name]
        end
      end
    end
  end
end
