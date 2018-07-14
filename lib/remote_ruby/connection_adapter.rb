module RemoteRuby
  class ConnectionAdapter
    def connection_name
      raise NotImplementedError
    end
  end
end

require 'remote_ruby/connection_adapter/local_stdin_adapter'
require 'remote_ruby/connection_adapter/ssh_stdin_adapter'
require 'remote_ruby/connection_adapter/cache_adapter'
require 'remote_ruby/connection_adapter/caching_adapter'
