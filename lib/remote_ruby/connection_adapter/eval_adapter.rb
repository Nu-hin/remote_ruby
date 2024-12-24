# frozen_string_literal: true

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
      with_pipes do |in_read, in_write, out_read, out_write, err_read, err_write|
        t = Thread.new do
          with_tmp_streams(in_read, out_write, err_write) do
            run_code(code)
          end

          in_read.close
          out_write.close
          err_write.close
        end

        yield in_write, out_read, err_read
        t.join
      end
    end

    private

    def run_code(code)
      binder = Object.new

      Dir.chdir(working_dir) do
        binder.instance_eval(code)
      end
    end

    def with_pipes
      in_read, in_write = IO.pipe
      out_read, out_write = IO.pipe
      err_read, err_write = IO.pipe
      yield in_read, in_write, out_read, out_write, err_read, err_write
    ensure
      in_read.close
      out_read.close
      err_read.close
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
