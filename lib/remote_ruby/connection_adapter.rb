# frozen_string_literal: true

module RemoteRuby
  # Base class for other connection adapters.
  class ConnectionAdapter
    # Initializers of adapters should receive only keyword arguments.
    # May be overriden in a child class.
    def initialize(**args); end

    # Override in child class. Receives Ruby code as string and yields
    # two readable streams: for emulated standard output and standard error.
    def open(_code)
      raise NotImplementedError
    end
  end
end

require 'remote_ruby/connection_adapter/eval_adapter'
require 'remote_ruby/connection_adapter/stdin_process_adapter'
require 'remote_ruby/connection_adapter/ssh_stdin_adapter'
require 'remote_ruby/connection_adapter/local_stdin_adapter'
require 'remote_ruby/connection_adapter/cache_adapter'
require 'remote_ruby/connection_adapter/caching_adapter'
