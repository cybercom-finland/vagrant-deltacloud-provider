
if ENV['COVERAGE'] != 'false'
  require 'simplecov'
  require 'coveralls'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
  ]
  SimpleCov.start do
    add_filter 'spec'
  end
end

Dir[
  'lib/vagrant-deltacloud-provider/config.rb',
  'lib/vagrant-deltacloud-provider/config_resolver.rb',
  'lib/vagrant-deltacloud-provider/utils.rb',
  'lib/vagrant-deltacloud-provider/errors.rb',
  'lib/vagrant-deltacloud-provider/provider.rb',
  'lib/vagrant-deltacloud-provider/client/*.rb',
  'lib/vagrant-deltacloud-provider/command/*.rb',
  'lib/vagrant-deltacloud-provider/action/*.rb'].each { |file| require file[4, file.length - 1] }

require 'rspec/its'
require 'webmock/rspec'
require 'fakefs/safe'
require 'fakefs/spec_helpers'

RSpec.configure do |config|
  config.include FakeFS::SpecHelpers, fakefs: true
end

I18n.load_path << File.expand_path('locales/en.yml', Pathname.new(File.expand_path('../../../', __FILE__)))
