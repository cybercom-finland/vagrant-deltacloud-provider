require 'log4r'
require 'restclient'
require 'json'

module VagrantPlugins
  module Deltacloud
    def list_public_keys(env)
      keys_list = get(env, "/keys")
      JSON.parse(keys_list)
    end
  end
end
