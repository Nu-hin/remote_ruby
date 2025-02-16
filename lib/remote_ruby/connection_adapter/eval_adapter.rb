# frozen_string_literal: true

require 'remote_ruby/pipes'
require 'remote_ruby/stream_splitter'

module RemoteRuby
  # An adapter to expecute Ruby code in the current process in an isolated
  # scope
  class EvalAdapter < ConnectionAdapter
    attr_reader :working_dir

    def initialize(working_dir: Dir.pwd)
      super
      @working_dir = working_dir
    end

    def open(code)
      Pipes.with_pipes do |p|
        t = Thread.new do
          run_code(code, p.in_r, p.out_w, p.err_w)
          p.close_w
        end

        out, res = StreamSplitter.split(p.out_r, Compiler::MARSHAL_TERMINATOR)

        yield p.in_w, out, p.err_r, res
        t.join
      end
    end

    private

    def run_code(code, in_read, out_write, err_write)
      binder = Object.new

      Dir.chdir(working_dir) do
        with_tmp_streams(in_read, out_write, err_write) do
          binder.instance_eval(code)
        end
      end
    end

    def with_tmp_streams(ins, out, err)
      old_stdin = $stdin
      old_stdout = $stdout
      old_stderr = $stderr
      $stdin = ins
      $stdout = out
      $stderr = err
      yield
    ensure
      $stdin = old_stdin
      $stdout = old_stdout
      $stderr = old_stderr
    end
  end
end
