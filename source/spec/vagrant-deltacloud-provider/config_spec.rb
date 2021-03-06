require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::Config do
  describe 'defaults' do
    let(:vagrant_public_key) { Vagrant.source_root.join('keys/vagrant.pub') }

    subject do
      super().tap do |o|
        o.finalize!
      end
    end

    its(:password)  { should be_nil }
    its(:deltacloud_compute_url) { should be_nil }
    its(:deltacloud_auth_url) { should be_nil }
    its(:hardware_profile)   { should be_nil }
    its(:image)    { should be_nil }
    its(:server_name) { should be_nil }
    its(:username) { should be_nil }
    its(:rsync_includes) { should be_nil }
    its(:public_key_name) { should be_nil }
    its(:public_key_path) { should be_nil }
    its(:availability_zone) { should be_nil }
    its(:ssh_username) { should be_nil }
    its(:scheduler_hints) { should be_nil }
    its(:security_groups) { should be_nil }
    its(:user_data) { should be_nil }
    its(:metadata) { should be_nil }
  end

  describe 'overriding defaults' do
    [
      :password,
      :deltacloud_compute_url,
      :deltacloud_auth_url,
      :hardware_profile,
      :image,
      :server_name,
      :username,
      :public_key_name,
      :ssh_username,
      :scheduler_hints,
      :security_groups,
      :user_data,
      :metadata,
      :availability_zone,
      :public_key_path].each do |attribute|
      it "should not default #{attribute} if overridden" do
        subject.send("#{attribute}=".to_sym, 'foo')
        subject.finalize!
        subject.send(attribute).should == 'foo'
      end
    end

    it 'should not default rsync_includes if overridden' do
      inc = 'core'
      subject.send(:rsync_include, inc)
      subject.finalize!
      subject.send(:rsync_includes).should include(inc)
    end
  end

  describe 'merge' do
    let(:foo_class) do
      Class.new(described_class) do
        attr_accessor :networks
      end
    end

    subject { foo_class.new }

    context 'with original network not empty' do
      it 'should overidde the config' do
        one = foo_class.new
        one.networks = ['foo']

        two = foo_class.new
        two.networks = ['bar']

        result = one.merge(two)
        result.networks.should =~ ['bar']
      end
    end

    context 'with original network empty' do
      it 'should add the network to the existing list' do
        one = foo_class.new
        one.networks = []

        two = foo_class.new
        two.networks = ['bar']

        result = one.merge(two)
        result.networks.should =~ ['bar']
      end
    end

    context 'with original network not empty and new empty' do
      it 'should keep the original network' do
        one = foo_class.new
        one.networks = ['foo']

        two = foo_class.new
        two.networks = []

        result = one.merge(two)
        result.networks.should =~ ['foo']
      end
    end
  end

  describe 'validation' do
    let(:machine) { double('machine') }
    let(:validation_errors) { subject.validate(machine)['Deltacloud Provider'] }
    let(:error_message) { double('error message') }

    let(:config) { double('config') }
    let(:ssh) { double('ssh') }

    before(:each) do
      error_message.stub(:yellow) { 'Yellowed Error message ' }
      machine.stub_chain(:env, :root_path).and_return '/'
      ssh.stub(:private_key_path) { 'private key path' }
      ssh.stub(:username) { 'ssh username' }
      config.stub(:ssh) { ssh }
      machine.stub(:config) { config }
      subject.username = 'foo'
      subject.password = 'bar'
      subject.public_key_name = 'public_key'
    end

    subject do
      super().tap do |o|
        o.finalize!
      end
    end

    context 'with invalid key' do
      it 'should raise an error' do
        subject.nonsense1 = true
        subject.nonsense2 = false
        I18n.should_receive(:t).with('vagrant.config.common.bad_field', fields: 'nonsense1, nonsense2').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    context 'with no ssh username provider' do
      it 'should raise an error' do
        ssh.stub(:username) { nil }
        subject.ssh_username = nil
        I18n.should_receive(:t).with('vagrant_deltacloud.config.ssh_username_required').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    context 'with good values' do
      it 'should validate' do
        validation_errors.should be_empty
      end
    end

    context 'private_key_path is not set' do
      context 'public_key_name or public_key_path is set' do
        it 'should error if not given' do
          ssh.stub(:private_key_path) { nil }
          subject.public_key_path = 'public_key'
          I18n.should_receive(:t).with('vagrant_deltacloud.config.private_key_missing').and_return error_message
          validation_errors.first.should == error_message
        end
      end
    end

    context 'the API key' do
      it 'should error if not given' do
        subject.password = nil
        I18n.should_receive(:t).with('vagrant_deltacloud.config.password_required').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    context 'the username' do
      it 'should error if not given' do
        subject.username = nil
        I18n.should_receive(:t).with('vagrant_deltacloud.config.username_required').and_return error_message
        validation_errors.first.should == error_message
      end
    end

    context 'the ssh_timeout' do
      it 'should error if do not represent an integer' do
        subject.ssh_timeout = 'timeout'
        I18n.should_receive(:t).with('vagrant_deltacloud.config.invalid_value_for_parameter',
                                     parameter: 'ssh_timeout', value: 'timeout').and_return error_message
        validation_errors.first.should == error_message
      end
      it 'should be parsed as integer if is a string that represent an integer' do
        subject.ssh_timeout = '100'
        validation_errors.size.should eq(0)
        expect(subject.ssh_timeout).to eq(100)
      end
    end

    [:deltacloud_compute_url, :deltacloud_auth_url].each do |url|
      context "the #{url}" do
        it 'should not validate if the URL is invalid' do
          subject.send "#{url}=", 'baz'
          I18n.should_receive(:t).with('vagrant_deltacloud.config.invalid_uri', key: url, uri: 'baz').and_return error_message
          validation_errors.first.should == error_message
        end
      end
    end
  end
end
