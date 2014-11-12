require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::Action::DeleteServer do

  let(:deltacloud) do
    double('deltacloud').tap do |app|
      app.stub(:delete_server)
      app.stub(:delete_public_key)
    end
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:info).with(anything)
      env[:ui].stub(:error).with(anything)
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
    context 'when id is present' do
      it 'delete server' do
        expect(deltacloud).to receive(:delete_server).with(env, 'server_id')
        expect(deltacloud).to receive(:delete_public_key).with(env, 'server_id')
        @action = DeleteServer.new(app, nil)
        @action.call(env)
      end
    end
    context 'when id is not present' do
      it 'delete server' do
        expect(deltacloud).should_not_receive(:delete_server)
        expect(deltacloud).should_not_receive(:delete_public_key)
        @action = DeleteServer.new(app, nil)
        @action.call(env)
      end
    end
  end
end
