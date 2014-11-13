require 'vagrant-deltacloud-provider/spec_helper'

include VagrantPlugins::Deltacloud::Action
include VagrantPlugins::Deltacloud::HttpUtils

describe VagrantPlugins::Deltacloud::Action::ReadSSHInfo do

  let(:config) do
    double('config').tap do |config|
      config.stub(:deltacloud_api_url) { 'https://standard.fi-central.cybercomcloud.com/api' }
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:username) { 'username' }
      config.stub(:password) { 'password' }
      config.stub(:ssh_username) { 'test_username' }
      config.stub(:public_key_name) { nil }
      config.stub(:public_key_path) { nil }
      config.stub(:ssh_disabled) { false }
    end
  end

  let(:ssh_config) do
    double('ssh_config').tap do |config|
      config.stub(:username) { 'sshuser' }
      config.stub(:port) { nil }
    end
  end

  let(:machine_config) do
    double('machine_config').tap do |config|
      config.stub(:ssh) { ssh_config }
    end
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:machine] = double('machine')
      env[:machine].stub(:provider_config) { config }
      env[:machine].stub(:config) { machine_config }
      env[:machine].stub(:id) { '1234' }
      env[:machine].stub(:data_dir) { '/data/dir' }
      env[:deltacloud_client] = double('deltacloud_client')
      env.stub(:deltacloud_client) { deltacloud }
    end
  end

  let(:app) do
    double('app').tap do |app|
      app.stub(:call).with(anything)
    end
  end

  before :each do
    ReadSSHInfo.send(:public, *ReadSSHInfo.private_instance_methods)
    @action = ReadSSHInfo.new(app, env)
  end

  describe 'call' do
    context 'when called three times' do
      it 'read ssh info only once' do
        config.stub(:public_key_name) { 'my_public_key' }
        @action.stub(:read_ssh_info) { { host: '', port: '', username: '' } }
        expect(@action).to receive(:read_ssh_info).exactly(1).times
        expect(app).to receive(:call)
        (1..3).each { @action.call(env) }
      end
    end
  end

  describe 'read_ssh_info' do
    context 'in a normal case' do
      it 'return the ip found by querying server details' do
        deltacloud.stub(:get_instance_details).with(env, '1234') do
          {
            'addresses' => {
              'toto' => [{
                'addr' => '13.13.13.13'
              }, {
                'addr' => '12.12.12.12',
                'OS-EXT-IPS:type' => 'fixed'
              }]
            }
          }
        end
        config.stub(:public_key_name) { 'my_public_key' }
        @action.read_ssh_info(env).should eq(host: '12.12.12.12', port: 22, username: 'sshuser', log_level: 'ERROR')
      end
    end
  end

end
