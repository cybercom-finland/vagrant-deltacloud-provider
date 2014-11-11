require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::Action::ReadState do

  let(:deltacloud) do
    double('deltacloud')
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
      it 'set the state to the one returned by deltacloud' do
        env[:machine].id = 'server_id'
        deltacloud.stub(:get_server_details).and_return('status' => 'ACTIVE')

        expect(deltacloud).to receive(:get_server_details).with(env, 'server_id')
        expect(app).to receive(:call)

        @action = ReadState.new(app, nil)
        @action.call(env)

        expect(env[:machine_state_id]).to eq(:active)
      end
    end
    context 'when server id is not present' do
      it 'set the state to :not_created' do
        env[:machine].id = nil
        expect(deltacloud).to_not receive(:get_server_details)
        expect(app).to receive(:call)

        @action = ReadState.new(app, nil)
        @action.call(env)

        expect(env[:machine_state_id]).to eq(:not_created)
      end
    end
    context 'when server cannot be found' do
      it 'set the state to :not_created' do
        env[:machine].id = 'server_id'
        deltacloud.stub(:get_server_details).and_return(nil)

        expect(deltacloud).to receive(:get_server_details).with(env, 'server_id')
        expect(app).to receive(:call)

        @action = ReadState.new(app, nil)
        @action.call(env)

        expect(env[:machine_state_id]).to eq(:not_created)
      end
    end
  end
end
