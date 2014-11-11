require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::Command::FlavorList do
  describe 'cmd' do

    let(:nova) do
      double('nova').tap do |nova|
        nova.stub(:get_all_flavors) do
          [
            Flavor.new('001', 'small', '1', '1024', '10'),
            Flavor.new('002', 'large', '4', '4096', '100')
          ]
        end
      end
    end

    let(:env) do
      Hash.new.tap do |env|
        env[:ui] = double('ui')
        env[:ui].stub(:info).with(anything)
        env[:deltacloud_client] = double
        env[:deltacloud_client].stub(:nova) { nova }
      end
    end

    before :each do
      @flavor_list_cmd = VagrantPlugins::Deltacloud::Command::FlavorList.new(nil, env)
    end

    it 'prints flovor list from server' do
      nova.should_receive(:get_all_flavors).with(env)

      expect(env[:ui]).to receive(:info).with('
+-----+-------+------+----------+----------------+
| Id  | Name  | vCPU | RAM (Mo) | Disk size (Go) |
+-----+-------+------+----------+----------------+
| 001 | small | 1    | 1024     | 10             |
| 002 | large | 4    | 4096     | 100            |
+-----+-------+------+----------+----------------+')

      @flavor_list_cmd.cmd('flavor-list', [], env)
    end
  end
end
