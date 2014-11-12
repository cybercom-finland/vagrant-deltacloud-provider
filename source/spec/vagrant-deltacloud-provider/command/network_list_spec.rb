require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::Command::NetworkList do
  describe 'cmd' do

    let(:deltacloud) do
      double('deltacloud').tap do |deltacloud|
        deltacloud.stub(:list_networks) do
          [
            Item.new('pub-01', 'public'),
            Item.new('net-01', 'internal'),
            Item.new('net-02', 'external')
          ]
        end
      end
    end

    let(:env) do
      Hash.new.tap do |env|
        env[:ui] = double('ui')
        env[:ui].stub(:info).with(anything)
        env.stub(:deltacloud_client) { deltacloud }
      end
    end

    before :each do
      @network_list_cmd = VagrantPlugins::Deltacloud::Command::NetworkList.new(nil, env)
    end

    it 'prints all networks list from server' do
      deltacloud.should_receive(:list_networks).with(env)

      expect(env[:ui]).to receive(:info).with('
+--------+----------+
| Id     | Name     |
+--------+----------+
| pub-01 | public   |
| net-01 | internal |
| net-02 | external |
+--------+----------+')

      @network_list_cmd.cmd('network-list', env)
    end

  end
end
