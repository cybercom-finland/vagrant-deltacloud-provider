require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::Command::FloatingIpList do
  describe 'cmd' do

    let(:deltacloud) do
      double('deltacloud').tap do |deltacloud|
        deltacloud.stub(:get_floating_ip_pools) do
          [
            {
              'name' => 'pool1'
            },
            {
              'name' => 'pool2'
            }
          ]
        end
        deltacloud.stub(:get_floating_ips) do
          [
            {
              'fixed_ip' => nil,
              'id' => 1,
              'instance_id' => nil,
              'ip' => '10.10.10.1',
              'pool' => 'pool1'
            },
            {
              'fixed_ip' => nil,
              'id' => 2,
              'instance_id' => 'inst001',
              'ip' => '10.10.10.2',
              'pool' => 'pool2'
            }
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
      @floating_ip_list_cmd = VagrantPlugins::Deltacloud::Command::FloatingIpList.new(nil, env)
    end

    it 'prints floating ip and floating ip pool from server' do
      deltacloud.should_receive(:get_floating_ip_pools).with(env)
      deltacloud.should_receive(:get_floating_ips).with(env)

      expect(env[:ui]).to receive(:info).with('
+-------------------+
| Floating IP pools |
+-------------------+
| pool1             |
| pool2             |
+-------------------+').ordered

      expect(env[:ui]).to receive(:info).with('
+----+------------+-------+-------------+
| Id | IP         | Pool  | Instance id |
+----+------------+-------+-------------+
| 1  | 10.10.10.1 | pool1 |             |
| 2  | 10.10.10.2 | pool2 | inst001     |
+----+------------+-------+-------------+').ordered

      @floating_ip_list_cmd.cmd('floatingip-list', [], env)
    end
  end
end
