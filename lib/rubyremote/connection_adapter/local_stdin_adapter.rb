require 'open3'

module Rubyremote
  # An adapter to expecute Ruby code on the local macine
  # inside a specified directory
  class LocalStdinAdapter < ConnectionAdapter
    register_adapter(:local_stdin)

    attr_reader :working_dir

    def initialize(working_dir:)
      @working_dir = working_dir
    end

    def connection_name
      working_dir
    end

    def open
      result = nil

      Dir.chdir(working_dir) do
        Open3.popen3('ruby') do |stdin, stdout, stderr, wait_thr|
          yield stdin, stdout, stderr
          result = wait_thr.value
        end
      end

      return if result.zero?
      raise "Remote connection exited with code #{result}"
    end
  end
end
