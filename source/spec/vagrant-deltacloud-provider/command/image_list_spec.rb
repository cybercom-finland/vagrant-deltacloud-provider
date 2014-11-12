require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::Command::ImageList do

  let(:deltacloud) do
    double('deltacloud').tap do |deltacloud|
      deltacloud.stub(:list_images) do
        [
          Image.new('0001', 'ubuntu'),
          Image.new('0002', 'centos'),
          Image.new('0003', 'debian')
        ]
      end
    end
  end

  let(:deltacloud) do
    double('deltacloud').tap do |deltacloud|
      deltacloud.stub(:list_images) do
        [
          Image.new('0001', 'ubuntu', 'public',  700 * 1024 * 1024, 1, 10),
          Image.new('0002', 'centos', 'private', 800 * 1024 * 1024, 2, 20),
          Image.new('0003', 'debian', 'shared',  900 * 1024 * 1024, 4, 30)
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
    @image_list_cmd = VagrantPlugins::Deltacloud::Command::ImageList.new(['--'], env)
  end

  describe 'cmd' do
    it 'prints image list with only the id and the name' do

      allow(@image_list_cmd).to receive(:with_target_vms).and_return(nil)
      deltacloud.should_receive(:list_images).with(env)

      expect(env[:ui]).to receive(:info).with('
+------+--------+
| Id   | Name   |
+------+--------+
| 0001 | ubuntu |
| 0002 | centos |
| 0003 | debian |
+------+--------+')
      @image_list_cmd.cmd('image-list', [], env)
    end
  end
end
