# frozen_string_literal: true

require 'open3'
require 'tempfile'

module RemoteRuby
  # An adapter to expecute Ruby code on the local machine
  # inside a temporary file
  class TmpFileAdapter < ::RemoteRuby::ConnectionAdapter
    attr_reader :working_dir

    def initialize(working_dir: Dir.pwd)
      super
      @working_dir = working_dir
    end

    def open(code)
      res_r, res_w = IO.pipe
      with_temp_file(code) do |filename|
        result = nil

        Open3.popen3(command(filename)) do |stdin, stdout, stderr, wait_thr|
          t = Thread.new(wait_thr) do
            result = wait_thr.value

            IO.copy_stream(filename, res_w) if result.success?
            res_w.close
          end

          yield stdin, stdout, stderr, res_r

          t.join
        end

        return if result.success?

        raise "Process exited with code #{result}"
      end
    end

    def connection_name
      "#{ENV.fetch('USER', nil)}@localhost:#{working_dir}> "
    end

    protected

    def with_temp_file(code)
      f = Tempfile.create('remote_ruby')
      f.write(code)
      f.close
      yield f.path
    ensure
      File.unlink(f.path)
    end

    def command(code_path)
      "cd \"#{working_dir}\" && ruby #{code_path}"
    end
  end
end
