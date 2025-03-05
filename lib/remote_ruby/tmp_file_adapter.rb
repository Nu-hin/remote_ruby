# frozen_string_literal: true

require 'tempfile'
require 'remote_ruby/compat_io_reader'
require 'remote_ruby/compat_io_writer'

module RemoteRuby
  # An adapter to expecute Ruby code on the local machine
  # inside a temporary file
  class TmpFileAdapter < ::RemoteRuby::ConnectionAdapter
    attr_reader :working_dir

    def initialize(working_dir: Dir.pwd)
      super
      @working_dir = working_dir
    end

    def open(code, stdin, stdout, stderr)
      result = nil

      stdin = RemoteRuby::CompatIOReader.new(stdin)
      stdout = RemoteRuby::CompatIOWriter.new(stdout)
      stderr = RemoteRuby::CompatIOWriter.new(stderr)

      with_temp_file(code) do |filename|
        pid = Process.spawn(
          command(filename),
          in: stdin.readable,
          out: stdout.writeable,
          err: stderr.writeable
        )

        _, status = Process.wait2(pid)
        raise "Process exited with code #{status}" unless status.success?

        [stdin, stdout, stderr].each(&:join)

        result = File.binread(filename)
      end
      result
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
      "cd \"#{working_dir}\" && ruby \"#{code_path}\""
    end
  end
end
