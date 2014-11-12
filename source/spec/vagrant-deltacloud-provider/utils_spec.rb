require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::Utils do

  let(:config) do
    double('config').tap do |config|
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:server_name) { 'testName' }
    end
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:machine] = double('machine')
      env[:machine].stub(:provider_config) { config }
      env[:machine].stub(:id) { '1234id' }
      env[:deltacloud_client] = double('deltacloud_client')
    end
  end

  before :each do
    Utils.send(:public, *Utils.private_instance_methods)
    @action = Utils.new
  end

  describe 'get_ip_address' do
    context 'with ip in deltacloud details' do
      context 'with on single ip in deltacloud details' do
        it 'returns the single ip' do
          deltacloud.stub(:get_server_details).with(env, '1234id') do
            {
              'addresses' => {
                'toto' => [{
                  'addr' => '13.13.13.13',
                  'OS-EXT-IPS:type' => 'fixed'
                }]
              }
            }
          end
          expect(@action.get_ip_address(env)).to eq('13.13.13.13')
        end
      end

      context 'with multiple ips in deltacloud details' do
        it 'fails' do
          deltacloud.stub(:get_server_details).with(env, '1234id') do
            {
              'addresses' => {
                'toto' => [{
                  'addr' => '13.13.13.13'
                }, {
                  'addr' => '12.12.12.12',
                  'OS-EXT-IPS:type' => 'private'
                }]
              }
            }
          end
          expect(@action.get_ip_address(env)).to eq('13.13.13.13')
        end
      end

      context 'with networks but no ips' do
        it 'fails' do
          deltacloud.stub(:get_server_details).with(env, '1234id') do
            {
              'addresses' => {
                'toto' => []
              }
            }
          end
          expect { @action.get_ip_address(env) }.to raise_error(Errors::UnableToResolveIP)
        end
      end

      context 'with no networks ' do
        it 'fails' do
          deltacloud.stub(:get_server_details).with(env, '1234id') do
            {
              'addresses' => {}
            }
          end
          expect { @action.get_ip_address(env) }.to raise_error(Errors::UnableToResolveIP)
        end
      end
    end
  end
end
