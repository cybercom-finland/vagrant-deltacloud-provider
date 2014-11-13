require 'vagrant-deltacloud-provider/spec_helper'
require 'ostruct'
require 'sshkey'

include VagrantPlugins::Deltacloud::Action
include VagrantPlugins::Deltacloud::HttpUtils

describe VagrantPlugins::Deltacloud::Action::CreateServer do

  let(:config) do
    double('config').tap do |config|
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:server_name) { 'testName' }
      config.stub(:image) { 'ubuntu' }
      config.stub(:availability_zone) { nil }
      config.stub(:scheduler_hints) { nil }
      config.stub(:security_groups) { nil }
      config.stub(:user_data) { nil }
      config.stub(:metadata) { nil }
    end
  end

  let(:image) do
    double('image').tap do |image|
      image.stub(:name) { 'image_name' }
      image.stub(:id) { 'image123' }
    end
  end

  let(:hardware_profile) do
    double('hardware_profile').tap do |hardware_profile|
      hardware_profile.stub(:name) { 'hardware_profile_name'  }
      hardware_profile.stub(:id) { 'hardware_profile123' }
    end
  end

  let(:deltacloud) do
    double('deltacloud')
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:machine] = double('machine')
      env[:machine] = OpenStruct.new.tap do |m|
        m.provider_config = config
        m.id = nil
      end
      env.stub(:deltacloud_client) { deltacloud }
    end
  end

  let(:resolver) do
    double('resolver').tap do |r|
      r.stub(:resolve_hardware_profile).with(anything) do
        HardwareProfile.new('hardware_profile-01', 'small', nil, nil, nil)
      end
      r.stub(:resolve_image).with(anything) do
        Item.new('image-01', 'ubuntu')
      end
      r.stub(:resolve_networks).with(anything) { 'net-001' }
      r.stub(:resolve_volumes).with(anything) do
        [{ id: 'vol-01', device: nil }]
      end
      r.stub(:resolve_public_key_name).with(anything) { 'key' }
      r.stub(:resolve_ip).with(anything) { '1.2.3.4' }
      r.stub(:resolve_security_groups).with(anything) do
        [{ name: 'group1' }, { name: 'group2' }]
      end
    end
  end

  let(:utils) do
    double('utils').tap do |u|
      u.stub(:get_ip_address) { '1.2.3.4' }
    end
  end

  before :each do
    CreateServer.send(:public, *CreateServer.private_instance_methods)
    app = double('app')
    app.stub(:call).with(anything)
    @action = CreateServer.new(app, nil, resolver, utils)
  end

  describe 'call' do
    context 'with no image specified' do
      it 'should raise an error' do
        config.stub(:image) { nil }
        expect { @action.call(env) }.to raise_error Errors::MissingBootOption
      end
    end
    context 'with full options' do
      it 'works' do
        allow(@action).to receive(:create_server).and_return('45678')
        allow(@action).to receive(:waiting_for_server_to_be_built)
        allow(@action).to receive(:attach_volumes)
        allow(@action).to receive(:waiting_for_server_to_be_reachable)

        expect(@action).to receive(:waiting_for_server_to_be_built).with(env, '45678')
        expect(@action).to receive(:attach_volumes).with(env, '45678', [{ id: 'vol-01', device: nil }])

        @action.call(env)
      end
    end
  end

  describe 'create_server' do
    context 'with all options specified' do
      it 'calls deltacloud with all the options' do
        deltacloud.stub(:create_server).with(
        env,
        name: 'testName',
        hardware_profile_ref: hardware_profile.id,
        image_ref: image.id,
        networks: [{ uuid: 'test-networks-1' }, { uuid: 'test-networks-2', fixed_ip: '1.2.3.4' }],
        public_key: 'test-public_key',
        availability_zone: 'test-az',
        scheduler_hints: 'test-sched-hints',
        security_groups: ['test-sec-groups'],
        user_data: 'test-user_data',
        metadata: 'test-metadata') do '1234'
        end

        options = {
          hardware_profile: hardware_profile,
          image: image,
          networks: [{ uuid: 'test-networks-1' }, { uuid: 'test-networks-2', fixed_ip: '1.2.3.4' }],
          volumes: [{ id: '001', device: :auto }, { id: '002', device: '/dev/vdc' }],
          public_key_name_name: 'test-public_key_name',
          availability_zone: 'test-az',
          scheduler_hints: 'test-sched-hints',
          security_groups: ['test-sec-groups'],
          user_data: 'test-user_data',
          metadata: 'test-metadata'
        }

        expect(@action.create_server(env, options)).to eq '1234'
      end
    end
    context 'with minimal configuration and a single network' do
      it 'calls deltacloud' do
        config.stub(:server_name) { nil }
        deltacloud.stub(:create_server).with(
          env,
          name: nil,
          hardware_profile_ref: hardware_profile.id,
          image_ref: image.id,
          networks: [{ uuid: 'test-networks-1' }],
          public_key_name: 'test-public_key_name',
          availability_zone: nil,
          scheduler_hints: nil,
          security_groups: [],
          user_data: nil,
          metadata: nil) do '1234'
        end

        options = {
          hardware_profile: hardware_profile,
          image: image,
          networks: [{ uuid: 'test-networks-1' }],
          volumes: [],
          public_key_name: 'test-public_key_name',
          availability_zone: nil,
          scheduler_hints: nil,
          security_groups: [],
          user_data: nil,
          metadata: nil
        }

        expect(@action.create_server(env, options)).to eq '1234'
      end
    end
  end

  describe 'waiting_for_server_to_be_built' do
    context 'when server is not yet active' do
      it 'become active after one retry' do
        deltacloud.stub(:get_instance_details).and_return({ 'status' => 'BUILD' }, { 'status' => 'ACTIVE' })
        deltacloud.should_receive(:get_instance_details).with(env, 'server-01').exactly(2).times
        @action.waiting_for_server_to_be_built(env, 'server-01', 1, 5)
      end
      it 'timeout before the server become active' do
        deltacloud.stub(:get_instance_details).and_return({ 'status' => 'BUILD' }, { 'status' => 'BUILD' })
        deltacloud.should_receive(:get_instance_details).with(env, 'server-01').at_least(2).times
        expect { @action.waiting_for_server_to_be_built(env, 'server-01', 1, 3) }.to raise_error Errors::Timeout
      end
      it 'raise an error after one retry' do
        deltacloud.stub(:get_instance_details).and_return({ 'status' => 'BUILD' }, { 'status' => 'ERROR' })
        deltacloud.should_receive(:get_instance_details).with(env, 'server-01').exactly(2).times
        expect { @action.waiting_for_server_to_be_built(env, 'server-01', 1, 3) }.to raise_error Errors::ServerStatusError
      end
    end
  end

  describe 'attach_volumes' do
    context 'with volume attached in all possible ways' do
      it 'returns normalized volume list' do
        deltacloud.stub(:attach_volume).with(anything, anything, anything, anything) {}
        deltacloud.should_receive(:attach_volume).with(env, 'server-01', '001', nil)
        deltacloud.should_receive(:attach_volume).with(env, 'server-01', '002', '/dev/vdb')

        @action.attach_volumes(env, 'server-01', [{ id: '001', device: nil }, { id: '002', device: '/dev/vdb' }])
      end
    end
  end
end
