require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::Command::HardwareProfileList do
  describe 'cmd' do

    let(:deltacloud) do
      double('deltacloud').tap do |deltacloud|
        deltacloud.stub(:list_hardware_profiles) do
          [
            HardwareProfile.new('1', 'XS', '1', '512', '10'),
            HardwareProfile.new('2', 'S', '1', '2048', '20')
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
      @hardware_profile_list_cmd = VagrantPlugins::Deltacloud::Command::HardwareProfileList.new(nil, env)
    end

    it 'prints hardware profile list from server' do
      deltacloud.should_receive(:get_all_hardwre_profiles).with(env)

      expect(env[:ui]).to receive(:info).with('
+-----+-------+------+----------+----------------+
| Id  | Name  | vCPU | RAM (Mo) | Disk size (Go) |
+-----+-------+------+----------+----------------+
| 001 | small | 1    | 1024     | 10             |
| 002 | large | 4    | 4096     | 100            |
+-----+-------+------+----------+----------------+')

      @hardware_profile_list_cmd.cmd('hardware-profile-list', [], env)
    end
  end
end
