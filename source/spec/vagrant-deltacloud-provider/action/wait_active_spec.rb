require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::Action::WaitForServerToBeActive do

  let(:deltacloud) do
    double('deltacloud')
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = double('ui').tap do |ui|
        ui.stub(:info).with(anything)
        ui.stub(:error).with(anything)
      end
      env.stub(:deltacloud_client) { deltacloud }
      env[:machine] = OpenStruct.new.tap do |m|
        m.id = 'server_id'
      end
    end
  end

  let(:app) do
    double('app').tap do |app|
      app.stub(:call).with(anything)
    end
  end

  describe 'call' do
    context 'when server is not yet active' do
      it 'become active after one retry' do
        deltacloud.stub(:get_instance_details).and_return({ 'status' => 'BUILD' }, { 'status' => 'RUNNING' })
        expect(deltacloud).to receive(:get_instance_details).with(env, 'server_id').exactly(2).times
        expect(app).to receive(:call)
        @action = WaitForServerToBeActive.new(app, nil, 1, 5)
        @action.call(env)
      end
      it 'timeout after one retry' do
        deltacloud.stub(:get_instance_details).and_return({ 'status' => 'BUILD' }, { 'status' => 'BUILD' })
        expect(deltacloud).to receive(:get_instance_details).with(env, 'server_id').at_least(2).times
        @action = WaitForServerToBeActive.new(app, nil, 1, 2)
        expect { @action.call(env) }.to raise_error Errors::Timeout
      end
    end
  end
end
