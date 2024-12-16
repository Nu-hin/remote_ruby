# frozen_string_literal: true

require 'remote_ruby/unmarshaler'

module RemoteRuby
  # Runner class is responsible for running a prepared Ruby code with given
  # connection adapter, reading output and unmarshalling result and local
  # variables values.
  class Runner
    def initialize(code:, adapter:, out_stream: $stdout, err_stream: $stderr)
      @code = code
      @adapter = adapter
      @out_stream = out_stream
      @err_stream = err_stream
    end

    def run
      locals = nil

      adapter.open(code) do |stdout, stderr|
        out_thread = read_stream(stdout, out_stream)
        err_thread = read_stream(stderr, err_stream)
        [out_thread, err_thread].each(&:join)
        locals = out_thread[:locals]
      end

      { result: locals[:__return_val__], locals: locals }
    end

    private

    attr_reader :code, :adapter, :out_stream, :err_stream

    def read_stream(read_from, write_to)
      Thread.new do
        until read_from.eof?
          line = read_from.readline

          if line.start_with?('%%%MARSHAL')
            Thread.current[:locals] ||= unmarshal(read_from)
          else
            write_to.puts line
          end
        end
      end
    end

    def unmarshal(stdout)
      unmarshaler = RemoteRuby::Unmarshaler.new(stdout)
      unmarshaler.unmarshal
    end
  end
end
