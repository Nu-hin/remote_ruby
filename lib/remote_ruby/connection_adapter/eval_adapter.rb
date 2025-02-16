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
          run_code(code, in_read, out_write, err_write)

          in_read.close
          out_write.close
          err_write.close
        end

        out, res = split_output_stream(out_read)

        yield in_write, out, err_read, res
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

    # rubocop:disable Style/ParallelAssignment
    def with_tmp_streams(ins, out, err)
      old_stdin, old_stdout, old_stderr = $stdin, $stdout, $stderr
      $stdin, $stdout, $stderr = ins, out, err
      yield
    ensure
      $stdin, $stdout, $stderr = old_stdin, old_stdout, old_stderr
    end
    # rubocop:enable Style/ParallelAssignment
  end
end
