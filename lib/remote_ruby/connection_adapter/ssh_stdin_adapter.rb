module RemoteRuby
  # An adapter to execute Ruby code on the remote server via SSH
  class SSHStdinAdapter < ExternalProcessAdapter
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

    private

    def command
      command = 'ssh'
      command = "#{command} -i #{key_file}" if key_file
      "#{command} #{server} \"cd #{working_dir} && ruby\""
    end
  end
end
