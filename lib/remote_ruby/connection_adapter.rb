# frozen_string_literal: true

module RemoteRuby
  # Base class for connection adapters.
  class ConnectionAdapter
    # Initializers of adapters should receive only keyword arguments.
    # May be overriden in a child class.
    def initialize(**args); end

    # Override in child class.
    # Accepts compiled Ruby code as string,
    # readable IO for stdin, writable IO for stdout and stderr.
    # Should return a binary result stream.
    def open(_code, _stdin, _stdout, _stderr)
      # :nocov:
      raise NotImplementedError
      # :nocov:
    end

    def connection_name
      "#{self.class.name} "
    end
  end
end

require 'remote_ruby/cache_adapter'
require 'remote_ruby/caching_adapter'
require 'remote_ruby/ssh_adapter'
require 'remote_ruby/tmp_file_adapter'
require 'remote_ruby/text_mode_adapter'
