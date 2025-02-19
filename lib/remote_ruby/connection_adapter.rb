# frozen_string_literal: true

module RemoteRuby
  # Base class for connection adapters.
  class ConnectionAdapter
    # Initializers of adapters should receive only keyword arguments.
    # May be overriden in a child class.
    def initialize(**args); end

    # Override in child class. Receives Ruby code as string and yields
    # a writeable stream for standard input and
    # two readable streams: for emulated standard output and standard error.
    def open(_code)
      raise NotImplementedError
    end

    def connection_name
      "#{self.class.name} "
    end
  end
end

require 'remote_ruby/eval_adapter'
require 'remote_ruby/cache_adapter'
require 'remote_ruby/caching_adapter'
require 'remote_ruby/ssh_adapter'
require 'remote_ruby/tmp_file_adapter'
require 'remote_ruby/text_mode_adapter'
