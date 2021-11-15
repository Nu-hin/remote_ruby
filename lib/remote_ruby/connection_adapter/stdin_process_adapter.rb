# frozen_string_literal: true

require 'open3'

module RemoteRuby
  # Base class for adapters which launch an external process to execute
  # Ruby code and send the code to its standard input.
  class StdinProcessAdapter < ::RemoteRuby::ConnectionAdapter
    include Open3

    def open(code)
      result = nil

      popen3(command) do |stdin, stdout, stderr, wait_thr|
        stdin.write(code)
        stdin.close

        yield stdout, stderr

        result = wait_thr.value
      end

      return if result.success?

      raise "Remote connection exited with code #{result}"
    end

    protected

    # Command to run an external process. Override in a child class.
    def command
      raise NotImplementedError
    end
  end
end
