require 'open3'

module RemoteRuby
  # An adapter to execute Ruby code on the remote server via SSH
  class SSHStdinAdapter < ConnectionAdapter
    include Open3

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

    private

    def command
      command = 'ssh'
      command = "#{command} -i #{key_file}" if key_file
      "#{command} #{server} \"cd #{working_dir} && ruby\""
    end
  end
end
