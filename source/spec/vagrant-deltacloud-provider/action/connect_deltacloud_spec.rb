require 'vagrant-deltacloud-provider/spec_helper'

include VagrantPlugins::Deltacloud::Action
include VagrantPlugins::Deltacloud::HttpUtils

describe VagrantPlugins::Deltacloud::Action::ConnectDeltacloud do

  let(:app) do
    double.tap do |app|
      app.stub(:call)
    end
  end

  let(:config) do
    double.tap do |config|
      config.stub(:deltacloud_api_url) { 'https://standard.fi-central.cybercomcloud.com/api' }
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:username) { 'username' }
      config.stub(:password) { 'password' }
    end
  end

  let(:deltacloud) do
    double.tap do |deltacloud|
      deltacloud.stub(:get_api_version_list).with(anything) do
        [
          {
            'status' => 'CURRENT',
            'id' => 'v2.0',
            'links' => [
              {
                'href' => 'https://standard.fi-central.cybercomcloud.com/api',
                'rel' => 'self'
              }
            ]
          }
        ]
      end
    end
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = double
      env[:ui].stub(:info).with(anything)
      env[:ui].stub(:warn).with(anything)
      env[:machine] = double('machine')
      env[:machine].stub(:provider_config) { config }
      env[:deltacloud_client] = double('deltacloud_client')
      env[:deltacloud_client].stub(:deltacloud) { deltacloud }
    end
  end

  before(:all) do
    ConnectDeltacloud.send(:public, *ConnectDeltacloud.private_instance_methods)
  end

  before :each do
    @action = ConnectDeltacloud.new(app, env)
  end
end
