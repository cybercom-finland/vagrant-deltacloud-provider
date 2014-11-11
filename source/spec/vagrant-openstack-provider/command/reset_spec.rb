require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::Command::Reset do
  describe 'cmd' do

    let(:env) do
      Hash.new.tap do |env|
        env[:ui] = double('ui')
        env[:ui].stub(:info).with(anything)
        env[:machine] = double('machine')
        env[:machine].stub(:data_dir) { '/my/data/dir' }
      end
    end

    before :each do
      @reset_cmd = VagrantPlugins::Deltacloud::Command::Reset.new(nil, env)
    end

    it 'resets vagrant deltacloud machines' do
      expect(env[:ui]).to receive(:info).with('Vagrant Deltacloud Provider has been reset')
      expect(FileUtils).to receive(:remove_dir).with('/my/data/dir')
      @reset_cmd.cmd('reset', [], env)
    end
  end
end
