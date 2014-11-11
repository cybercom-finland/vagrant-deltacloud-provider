require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::Command::NetworkList do
  describe 'cmd' do

    let(:deltacloud) do
      double('deltacloud').tap do |neutron|
        neutron.stub(:get_private_networks) do
          [
            Item.new('net-01', 'internal'),
            Item.new('net-02', 'external')
          ]
        end
        neutron.stub(:get_all_networks) do
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
        env[:deltacloud_client] = double
        env[:deltacloud_client].stub(:deltacloud) { deltacloud }
      end
    end

    before :each do
      @network_list_cmd = VagrantPlugins::Deltacloud::Command::NetworkList.new(nil, env)
    end

    it 'prints network list from server' do
      deltacloud.should_receive(:get_private_networks).with(env)

      expect(env[:ui]).to receive(:info).with('
+--------+----------+
| Id     | Name     |
+--------+----------+
| net-01 | internal |
| net-02 | external |
+--------+----------+')

      @network_list_cmd.cmd('network-list', [], env)
    end

    it 'prints all networks list from server' do
      deltacloud.should_receive(:get_all_networks).with(env)

      expect(env[:ui]).to receive(:info).with('
+--------+----------+
| Id     | Name     |
+--------+----------+
| pub-01 | public   |
| net-01 | internal |
| net-02 | external |
+--------+----------+')

      @network_list_cmd.cmd('network-list', ['all'], env)
    end

  end
end
