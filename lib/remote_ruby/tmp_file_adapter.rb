# frozen_string_literal: true

require 'open3'
require 'remote_ruby/stream_splitter'

module RemoteRuby
  # An adapter to expecute Ruby code on the local machine
  # inside a temporary file
  class TmpFileAdapter < ::RemoteRuby::ConnectionAdapter
    attr_reader :working_dir

    def initialize(working_dir: '.')
      super
      @working_dir = working_dir
    end

    def open(code)
      with_temp_file(code) do |filename|
        result = nil

        Open3.popen3(command(filename)) do |stdin, stdout, stderr, wait_thr|
          out, res = StreamSplitter.split(stdout, Compiler::MARSHAL_TERMINATOR)
          yield stdin, out, stderr, res

          result = wait_thr.value
        end

        return if result.success?

        raise "Process exited with code #{result}"
      end
    end

    protected

    def with_temp_file(code)
      Dir.mktmpdir do |dir|
        filename = File.join(dir, 'remote_ruby.rb')
        File.write(filename, code)
        yield filename
      end
    end

    def command(code_path)
      "cd \"#{working_dir}\" && ruby #{code_path}"
    end
  end
end
