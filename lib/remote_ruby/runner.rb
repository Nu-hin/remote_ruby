# frozen_string_literal: true

require 'remote_ruby/unmarshaler'

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
      locals = nil

      adapter.open(code) do |stdin, stdout, stderr, result|
        in_thread = read_stream(in_stream, stdin) unless stdin.nil?
        out_thread = read_stream(stdout, out_stream)
        err_thread = read_stream(stderr, err_stream)
        [out_thread, err_thread].each(&:join)
        locals = unmarshal(result)
        stdin&.close
        in_thread&.kill
      end

      {
        result: locals.delete(:__return_val__),
        exception_class: locals.delete(:__exception_class__),
        exception_message: locals.delete(:__exception_message__),
        exception_backtrace: locals.delete(:__exception_backtrace__),
        locals: locals
      }
    end

    private

    attr_reader :code, :adapter, :in_stream, :out_stream, :err_stream

    def read_stream(read_from, write_to)
      Thread.new do
        IO.copy_stream(read_from, write_to)
      end
    end

    def unmarshal(result)
      unmarshaler = RemoteRuby::Unmarshaler.new(result)
      unmarshaler.unmarshal
    end
  end
end
