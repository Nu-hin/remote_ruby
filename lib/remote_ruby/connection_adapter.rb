# frozen_string_literal: true

require 'remote_ruby/stream_splitter'

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

    protected

    def with_pipes
      in_read, in_write = IO.pipe
      out_read, out_write = IO.pipe
      err_read, err_write = IO.pipe
      yield in_read, in_write, out_read, out_write, err_read, err_write
    ensure
      in_write.close
      out_read.close
      err_read.close
    end

    def split_output_stream(stdout)
      [
        StreamSplitter.new(stdout, ::RemoteRuby::Compiler::MARSHAL_TERMINATOR),
        stdout
      ]
    end
  end
end

require 'remote_ruby/connection_adapter/eval_adapter'
require 'remote_ruby/connection_adapter/cache_adapter'
require 'remote_ruby/connection_adapter/caching_adapter'
require 'remote_ruby/connection_adapter/ssh_adapter'
require 'remote_ruby/connection_adapter/tmp_file_adapter'
require 'remote_ruby/connection_adapter/text_mode_adapter'
