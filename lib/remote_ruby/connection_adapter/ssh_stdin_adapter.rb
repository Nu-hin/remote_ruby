require 'open3'

module RemoteRuby
  # An adapter to execute Ruby code on the remote server via SSH
  class SSHStdinAdapter < ConnectionAdapter
    register_adapter(:ssh_stdin)

    attr_reader :server, :working_dir

    def initialize(server:, working_dir: '~')
      @server = server
      @working_dir = working_dir
    end

    def connection_name
      "#{server}:#{working_dir}"
    end

    def open
      result = nil

      remote_command = "\"cd #{working_dir} && ruby\""
      command = "ssh #{server} #{remote_command}"

      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        yield stdin, stdout, stderr
        result = wait_thr.value
      end

      return if result.success?

      raise "Remote connection exited with code #{result}"
    end
  end
end
