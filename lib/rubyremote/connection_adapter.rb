module Rubyremote
  class ConnectionAdapter
    attr_reader :server, :working_dir

    def self.register_adapter(name)
      @@adapters ||= {}
      @@adapters[name] = self
    end

    def self.build(adapter, params = {})
      klass = @@adapters[adapter]
      raise "Uknown adapter #{adapter}." unless klass
      klass.new(**params)
    end

    def connection_name
      raise NotImplementedError
    end
  end
end

require 'rubyremote/connection_adapter/local_stdin_adapter'
require 'rubyremote/connection_adapter/ssh_stdin_adapter'
require 'rubyremote/connection_adapter/cache_adapter'
require 'rubyremote/connection_adapter/caching_adapter'
