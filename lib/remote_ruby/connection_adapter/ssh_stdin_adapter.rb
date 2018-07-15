require 'open3'

module RemoteRuby
  # An adapter to execute Ruby code on the remote server via SSH
  class SSHStdinAdapter < ConnectionAdapter
    attr_reader :server, :working_dir, :user, :key_file

    def initialize(server:, working_dir: '~', user: nil, key_file: nil)
      @working_dir = working_dir
      @server = user.nil? ? server : "#{user}@#{server}"
      @user = user
      @key_file = key_file
    end

    def connection_name
      "#{server}:#{working_dir}"
    end

    def open
      command = 'ssh'
      command = "#{command} -i #{key_file}" if key_file
      command = "#{command} #{server} \"cd #{working_dir} && ruby\""

      result = nil

      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        yield stdin, stdout, stderr
        result = wait_thr.value
      end

      return if result.success?

      raise "Remote connection exited with code #{result}"
    end
  end
end
