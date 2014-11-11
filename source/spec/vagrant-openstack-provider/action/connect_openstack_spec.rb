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
      config.stub(:deltacloud_auth_url) { 'http://keystoneAuthV2' }
      config.stub(:deltacloud_compute_url) { nil }
      config.stub(:deltacloud_network_url) { nil }
      config.stub(:deltacloud_volume_url) { nil }
      config.stub(:deltacloud_image_url) { nil }
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:username) { 'username' }
      config.stub(:password) { 'password' }
    end
  end

  let(:neutron) do
    double.tap do |neutron|
      neutron.stub(:get_api_version_list).with(anything) do
        [
          {
            'status' => 'CURRENT',
            'id' => 'v2.0',
            'links' => [
              {
                'href' => 'http://neutron/v2.0',
                'rel' => 'self'
              }
            ]
          }
        ]
      end
    end
  end

  let(:glance) do
    double.tap do |glance|
      glance.stub(:get_api_version_list).with(anything) do
        [
          {
            'status' => 'CURRENT',
            'id' => 'v2.1',
            'links' => [
              {
                'href' => 'http://glance/v2.0',
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
      env[:deltacloud_client].stub(:neutron) { neutron }
      env[:deltacloud_client].stub(:glance) { glance }
    end
  end

  before(:all) do
    ConnectDeltacloud.send(:public, *ConnectDeltacloud.private_instance_methods)
  end

  before :each do
    VagrantPlugins::Deltacloud.session.reset
    @action = ConnectDeltacloud.new(app, env)
  end

  describe 'ConnectDeltacloud' do
    context 'with one endpoint by service' do
      it 'read service catalog and stores endpoints URL in session' do
        catalog = [
          {
            'endpoints' => [
              {
                'publicURL' => 'http://nova/v2/projectId',
                'id' => '1'
              }
            ],
            'type' => 'compute',
            'name' => 'nova'
          },
          {
            'endpoints' => [
              {
                'publicURL' => 'http://neutron',
                'id' => '2'
              }
            ],
            'type' => 'network',
            'name' => 'neutron'
          },
          {
            'endpoints' => [
              {
                'publicURL' => 'http://cinder/v2/projectId',
                'id' => '2'
              }
            ],
            'type' => 'volume',
            'name' => 'cinder'
          },
          {
            'endpoints' => [
              {
                'publicURL' => 'http://glance',
                'id' => '2'
              }
            ],
            'type' => 'image',
            'name' => 'glance'
          }
        ]

        double.tap do |keystone|
          keystone.stub(:authenticate).with(anything) { catalog }
          env[:deltacloud_client].stub(:keystone) { keystone }
        end
        env[:deltacloud_client].stub(:neutron)  { neutron }
        env[:deltacloud_client].stub(:glance)   { glance }

        @action.call(env)

        expect(env[:deltacloud_client].session.endpoints)
          .to eq(compute: 'http://nova/v2/projectId',
                 network: 'http://neutron/v2.0',
                 volume:  'http://cinder/v2/projectId',
                 image:   'http://glance/v2.0')
      end
    end

    context 'with multiple endpoints for a service' do
      it 'takes the first one' do
        catalog = [
          {
            'endpoints' => [
              {
                'publicURL' => 'http://neutron/alt',
                'id' => '2'
              },
              {
                'publicURL' => 'http://neutron',
                'id' => '3'
              }
            ],
            'type' => 'network',
            'name' => 'neutron'
          }
        ]

        double.tap do |keystone|
          keystone.stub(:authenticate).with(anything) { catalog }
          env[:deltacloud_client].stub(:keystone) { keystone }
        end
        env[:deltacloud_client].stub(:neutron) { neutron }

        @action.call(env)

        expect(env[:deltacloud_client].session.endpoints).to eq(network: 'http://neutron/v2.0')
      end
    end

    context 'with no matching versions for network service' do

      let(:neutron) do
        double.tap do |neutron|
          neutron.stub(:get_api_version_list).with(anything) do
            [
              {
                'status' => 'CURRENT',
                'id' => 'v1.1',
                'links' => [
                  {
                    'href' => 'http://neutron/v1.1',
                    'rel' => 'self'
                  }
                ]
              },
              {
                'status' => '...',
                'id' => 'v1.0',
                'links' => [
                  {
                    'href' => 'http://neutron/v1.0',
                    'rel' => 'self'
                  }
                ]
              }
            ]
          end
        end
      end

      it 'raise an error' do
        catalog = [
          {
            'endpoints' => [
              {
                'publicURL' => 'http://neutron',
                'id' => '3'
              }
            ],
            'type' => 'network',
            'name' => 'neutron'
          }
        ]

        double.tap do |keystone|
          keystone.stub(:authenticate).with(anything) { catalog }
          env[:deltacloud_client].stub(:keystone) { keystone }
        end
        env[:deltacloud_client].stub(:neutron) { neutron }

        expect { @action.call(env) }.to raise_error(Errors::NoMatchingApiVersion)
      end
    end

    context 'with only keystone and nova' do
      it 'read service catalog and stores endpoints URL in session' do
        catalog = [
          {
            'endpoints' => [
              {
                'publicURL' => 'http://nova/v2/projectId',
                'id' => '1'
              }
            ],
            'type' => 'compute',
            'name' => 'nova'
          },
          {
            'endpoints' => [
              {
                'publicURL' => 'http://keystone/v2.0',
                'id' => '2'
              }
            ],
            'type' => 'identity',
            'name' => 'keystone'
          }
        ]

        double.tap do |keystone|
          keystone.stub(:authenticate).with(anything) { catalog }
          env[:deltacloud_client].stub(:keystone) { keystone }
        end

        @action.call(env)

        expect(env[:deltacloud_client].session.endpoints)
        .to eq(compute: 'http://nova/v2/projectId', identity: 'http://keystone/v2.0')
      end
    end
  end
end
