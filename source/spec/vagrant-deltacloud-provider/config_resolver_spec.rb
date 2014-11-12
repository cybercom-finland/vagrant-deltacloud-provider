require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::ConfigResolver do

  let(:config) do
    double('config').tap do |config|
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:server_name) { 'testName' }
      config.stub(:public_key_name) { nil }
      config.stub(:public_key_path) { nil }
      config.stub(:networks) { nil }
      config.stub(:volumes) { nil }
    end
  end

  let(:ssh_key) do
    double('ssh_key').tap do |key|
      key.stub(:ssh_public_key) { 'ssh public key' }
      key.stub(:private_key) { 'private key' }
    end
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:machine] = double('machine')
      env[:machine].stub(:provider_config) { config }
      env[:machine].stub(:data_dir) { '/data/dir' }
      env[:machine].stub(:config) { machine_config }
      env[:deltacloud_client] = double('deltacloud_client')
    end
  end

  let(:ssh_config) do
    double('ssh_config').tap do |config|
      config.stub(:username) { nil }
      config.stub(:port) { nil }
    end
  end

  let(:machine_config) do
    double('machine_config').tap do |config|
      config.stub(:ssh) { ssh_config }
    end
  end

  before :each do
    ConfigResolver.send(:public, *ConfigResolver.private_instance_methods)
    @action = ConfigResolver.new
  end

  describe 'resolve_ssh_username' do
    context 'with machine.ssh.username' do
      it 'returns machine.ssh.username' do
        ssh_config.stub(:username) { 'machine ssh username' }
        config.stub(:ssh_username) { nil }
        expect(@action.resolve_ssh_username(env)).to eq('machine ssh username')
      end
    end
    context 'with machine.ssh.username and config.ssh_username' do
      it 'returns machine.ssh.username' do
        ssh_config.stub(:username) { 'machine ssh username' }
        config.stub(:ssh_username) { 'provider ssh username' }
        expect(@action.resolve_ssh_username(env)).to eq('machine ssh username')
      end
    end
    context 'with config.ssh_username' do
      it 'returns config.ssh_username' do
        ssh_config.stub(:username) { nil }
        config.stub(:ssh_username) { 'provider ssh username' }
        expect(@action.resolve_ssh_username(env)).to eq('provider ssh username')
      end
    end
    context 'with no ssh username config' do
      it 'fails' do
        ssh_config.stub(:username) { nil }
        config.stub(:ssh_username) { nil }
        expect { @action.resolve_ssh_username(env) }.to raise_error(Errors::NoMatchingSshUsername)
      end
    end
  end

  describe 'resolve_hardware_profile' do
    context 'with id' do
      it 'returns the specified hardware_profile' do
        config.stub(:hardware_profile) { 'hp-001' }
        deltacloud.stub(:list_hardware_profiles).with(anything) do
          [HardwareProfile.new('hp-001', 'hardware_profile-01', 2, 1024, 10),
           HardwareProfile.new('hp-002', 'hardware_profile-02', 4, 2048, 50)]
        end
        @action.resolve_hardware_profile(env).should eq(HardwareProfile.new('hp-001', 'hardware-profile-01', 2, 1024, 10))
      end
    end
    context 'with name' do
      it 'returns the specified hardware_profile' do
        config.stub(:hardware_profile) { 'hardware_profile-02' }
        deltacloud.stub(:list_hardware_profiles).with(anything) do
          [HardwareProfile.new('hp-001', 'hardware_profile-01', 2, 1024, 10),
           HardwareProfile.new('hp-002', 'hardware_profile-02', 4, 2048, 50)]
        end
        @action.resolve_hardware_profile(env).should eq(HardwareProfile.new('hp-002', 'hardware-profile-02', 4, 2048, 50))
      end
    end
    context 'with invalid identifier' do
      it 'raise an error' do
        config.stub(:hardware_profile) { 'not-existing' }
        deltacloud.stub(:list_hardware_profiles).with(anything) do
          [HardwareProfile.new('hp-001', 'hardware_profile-01', 2, 1024, 10),
          HardwareProfile.new('hp-002', 'hardware_profile-02', 4, 2048, 50)]
        end
        expect { @action.resolve_hardware_profile(env) }.to raise_error(Errors::NoMatchingHardwareProfile)
      end
    end
  end

  describe 'resolve_image' do
    context 'with id' do
      it 'returns the specified image' do
        config.stub(:image) { 'img-001' }
        deltacloud.stub(:get_all_images).with(anything) do
          [Item.new('img-001', 'image-01'),
           Item.new('img-002', 'image-02')]
        end
        @action.resolve_image(env).should eq(Item.new('img-001', 'image-01'))
      end
    end
    context 'with name' do
      it 'returns the specified image' do
        config.stub(:image) { 'image-02' }
        deltacloud.stub(:get_all_images).with(anything) do
          [Item.new('img-001', 'image-01'),
           Item.new('img-002', 'image-02')]
        end
        @action.resolve_image(env).should eq(Item.new('img-002', 'image-02'))
      end
    end
    context 'with invalid identifier' do
      it 'raise an error' do
        config.stub(:image) { 'not-existing' }
        deltacloud.stub(:get_all_images).with(anything) do
          [Item.new('img-001', 'image-01'),
           Item.new('img-002', 'image-02')]
        end
        expect { @action.resolve_image(env) }.to raise_error(Errors::NoMatchingImage)
      end
    end
  end

  describe 'resolve_public_key_name' do
    context 'with public_key_name provided' do
      it 'return the provided public_key_name' do
        config.stub(:public_key_name) { 'my-public_key' }
        @action.resolve_public_key_name(env).should eq('my-public_key')
      end
    end

    context 'with public_key_name and public_key_path provided' do
      it 'return the provided public_key_name' do
        config.stub(:public_key_name) { 'my-public_key' }
        config.stub(:public_key_path) { '/path/to/key' }
        @action.resolve_public_key_name(env).should eq('my-public_key')
      end
    end

    context 'with public_key_path provided' do
      it 'return the public_key_name created into deltacloud' do
        config.stub(:public_key_path) { '/path/to/key' }
        deltacloud.stub(:import_public_key_from_file).with(env, '/path/to/key') { 'my-public_key-imported' }
        @action.resolve_public_key_name(env).should eq('my-public_key-imported')
      end
    end

    context 'with no public_key_name and no public_key_path provided' do
      it 'generates a new public_key_name and return the public_key name imported into deltacloud' do
        config.stub(:public_key_name) { nil }
        config.stub(:public_key_path) { nil }
        @action.stub(:generate_keypair) { 'my-public_key-imported' }
        @action.resolve_public_key_name(env).should eq('my-public_key-imported')
      end
    end
  end

  describe 'generate_keypair' do
    it 'returns a generated keypair name imported into deltacloud' do
      deltacloud.stub(:import_public_key) { 'my-public_key-imported' }
      SSHKey.stub(:generate) { ssh_key }
      File.should_receive(:write).with('/data/dir/my-public_key-imported', 'private key')
      File.should_receive(:chmod).with(0600, '/data/dir/my-public_key-imported')
      @action.generate_keypair(env).should eq('my-public_key-imported')
    end
  end

  describe 'resolve_security_groups' do
    context 'with Hash and String objects' do
      it 'returns normalized Hash list' do
        config.stub(:security_groups) { ['group1', { name: 'group2' }] }
        expect(@action.resolve_security_groups(env)).to eq([{ name: 'group1' }, { name: 'group2' }])
      end
    end
  end
end
