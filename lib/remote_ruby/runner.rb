# frozen_string_literal: true

require 'remote_ruby/remote_context'

module RemoteRuby
  # Runner class is responsible for running a prepared Ruby code with given
  # connection adapter, reading output and unmarshalling result and local
  # variables values.
  class Runner
    def initialize(code:, adapter:, in_stream: $stdin, out_stream: $stdout, err_stream: $stderr)
      @code = code
      @adapter = adapter
      @in_stream = in_stream
      @out_stream = out_stream
      @err_stream = err_stream
    end

    def run
      context = nil

      adapter.open(code) do |stdin, stdout, stderr, result|
        in_thread = read_stream(in_stream, stdin) unless stdin.nil?
        out_thread = read_stream(stdout, out_stream)
        err_thread = read_stream(stderr, err_stream)
        [out_thread, err_thread].each(&:join)
        context = Marshal.load(result.is_a?(IO) ? result : result.read) # rubocop:disable Security/MarshalLoad
        stdin&.close
        in_thread&.kill
      end

      context
    end

    private

    attr_reader :code, :adapter, :in_stream, :out_stream, :err_stream

    def read_stream(read_from, write_to)
      Thread.new do
        IO.copy_stream(read_from, write_to)
      end
    end
  end
end
