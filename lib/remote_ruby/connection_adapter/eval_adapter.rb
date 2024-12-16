# frozen_string_literal: true

module RemoteRuby
  # An adapter to expecute Ruby code in the current process in an isolated
  # scope
  class EvalAdapter < ConnectionAdapter
    attr_reader :async, :working_dir

    def initialize(working_dir: Dir.pwd, async: false)
      super
      @async = async
      @working_dir = working_dir
    end

    def open(code, &block)
      if async
        run_async(code, &block)
      else
        run_sync(code, &block)
      end
    end

    private

    def run_code(code)
      binder = Object.new

      Dir.chdir(working_dir) do
        binder.instance_eval(code)
      end
    end

    def run_sync(code)
      with_stringio do |tmp_stdout, tmp_stderr|
        with_tmp_streams(tmp_stdout, tmp_stderr) do
          run_code(code)
        end

        tmp_stdout.close_write
        tmp_stderr.close_write
        tmp_stdout.rewind
        tmp_stderr.rewind
        yield tmp_stdout, tmp_stderr
      end
    end

    def run_async(code)
      with_pipes do |out_read, out_write, err_read, err_write|
        Thread.new do
          with_tmp_streams(out_write, err_write) do
            run_code(code)
          end

          out_write.close
          err_write.close
        end

        yield out_read, err_read
      end
    end

    def with_pipes
      out_read, out_write = IO.pipe
      err_read, err_write = IO.pipe
      yield out_read, out_write, err_read, err_write
    ensure
      out_read.close
      err_read.close
    end

    def with_stringio
      out = StringIO.new
      err = StringIO.new

      yield out, err
    ensure
      out.close
      err.close
    end

    def with_tmp_streams(out, err)
      old_stdout = $stdout
      old_stderr = $stderr
      $stdout = out
      $stderr = err
      yield
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end
  end
end
