# frozen_string_literal: true

module RemoteRuby
  # An adapter to execute Ruby code on the remote server via SSH
  class SSHStdinAdapter < StdinProcessAdapter
    attr_reader :server, :working_dir, :user, :key_file, :bundler

    def initialize(server:, working_dir: '~', user: nil, key_file: nil, bundler: false)
      super
      @working_dir = working_dir
      @server = user.nil? ? server : "#{user}@#{server}"
      @user = user
      @key_file = key_file
      @bundler = bundler
    end

    def connection_name
      "#{server}:#{working_dir}"
    end

    private

    def command
      command = 'ssh'
      command = "#{command} -i #{key_file}" if key_file

      if bundler
        "#{command} #{server} \"cd #{working_dir} && bundle exec ruby\""
      else
        "#{command} #{server} \"cd #{working_dir} && ruby\""
      end
    end
  end
end
