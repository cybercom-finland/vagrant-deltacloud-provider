require 'vagrant-deltacloud-provider/spec_helper'

describe VagrantPlugins::Deltacloud::Provider do
  before :each do
    @provider = VagrantPlugins::Deltacloud::Provider.new :machine
  end

  describe 'to string' do
    it 'should give the provider name' do
      @provider.to_s.should eq('Deltacloud Cloud')
    end
  end
end
