require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::KeystoneClient do

  let(:config) do
    double('config').tap do |config|
      config.stub(:deltacloud_api_url) { 'https://standard.fi-central.cybercomcloud.com/api' }
      config.stub(:tenant_name) { 'testTenant' }
      config.stub(:username) { 'username' }
      config.stub(:password) { 'password' }
    end
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:machine] = double('machine')
      env[:machine].stub(:provider_config) { config }
    end
  end

  let(:session) do
    VagrantPlugins::Deltacloud.session
  end

  describe 'authenticate' do

    let(:keystone_request_headers) do
      {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json'
      }
    end

    let(:keystone_request_body) do
      '{"auth":{"tenantName":"testTenant","passwordCredentials":{"username":"username","password":"password"}}}'
    end

    let(:keystone_response_body) do
      '{"access":{"token":{"id":"0123456789","tenant":{"id":"testTenantId"}},"serviceCatalog":[
         {"endpoints":[{"id":"eid1","publicURL":"http://nova"}],"type":"compute"},
         {"endpoints":[{"id":"eid2","publicURL":"http://neutron"}],"type":"network"}
       ]}}'
    end

    before :each do
      @keystone_client = VagrantPlugins::Deltacloud.keystone
    end

    context 'with good credentials' do
      it 'store token and tenant id' do
        stub_request(:post, 'http://keystoneAuthV2')
        .with(
            body: keystone_request_body,
            headers: keystone_request_headers)
        .to_return(
            status: 200,
            body: keystone_response_body,
            headers: keystone_request_headers)

        @keystone_client.authenticate(env)

        session.token.should eq('0123456789')
        session.project_id.should eq('testTenantId')
      end
    end

    context 'with wrong credentials' do
      it 'raise an unauthorized error' do
        stub_request(:post, 'http://keystoneAuthV2')
        .with(
            body: keystone_request_body,
            headers: keystone_request_headers)
        .to_return(
            status: 401,
            body: '{
                "error": {
                  "message": "The request you have made requires authentication.",
                  "code": 401,
                  "title": "Unauthorized"
               }
              }',
            headers: keystone_request_headers)

        expect { @keystone_client.authenticate(env) }.to raise_error(Errors::AuthenticationFailed)
      end
    end

    context 'with bad endpoint' do
      it 'raise a BadAuthenticationEndpoint error' do
        stub_request(:post, 'http://keystoneAuthV2')
        .with(
            body: keystone_request_body,
            headers: keystone_request_headers)
        .to_return(
            status: 404)

        expect { @keystone_client.authenticate(env) }.to raise_error(Errors::BadAuthenticationEndpoint)
      end
    end

    context 'with internal server error' do
      it 'raise a VagrantDeltacloudError error with response body as message' do
        stub_request(:post, 'http://keystoneAuthV2')
        .with(
            body: keystone_request_body,
            headers: keystone_request_headers)
        .to_return(
            status: 500,
            body: 'Internal server error')

        begin
          @keystone_client.authenticate(env)
          fail 'Expected Errors::VagrantDeltacloudError'
        rescue Errors::VagrantDeltacloudError => e
          e.message.should eq('Internal server error')
        end
      end
    end
  end
end
