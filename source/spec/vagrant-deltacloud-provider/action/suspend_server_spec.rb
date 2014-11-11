require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::Action::Suspend do

  let(:deltacloud) do
    double('deltacloud').tap do |deltacloud|
      deltacloud.stub(:suspend_server)
    end
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = double('ui').tap do |ui|
        ui.stub(:info).with(anything)
        ui.stub(:error).with(anything)
      end
      env[:deltacloud_client] = double('deltacloud_client').tap do |os|
        os.stub(:deltacloud) { deltacloud }
      end
      env[:machine] = OpenStruct.new
    end
  end

  let(:app) do
    double('app').tap do |app|
      app.stub(:call).with(anything)
    end
  end

  describe 'call' do
    context 'when server id is present' do
      it 'starts the server' do
        env[:machine].id = 'server_id'
        expect(deltacloud).to receive(:suspend_server).with(env, 'server_id')
        expect(app).to receive(:call)
        @action = Suspend.new(app, nil)
        @action.call(env)
      end
    end
    context 'when server id is not present' do
      it 'does nothing' do
        env[:machine].id = nil
        expect(deltacloud).to_not receive(:suspend_server)
        expect(app).to receive(:call)
        @action = Suspend.new(app, nil)
        @action.call(env)
      end
    end
  end
end
