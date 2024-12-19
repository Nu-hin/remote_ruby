# frozen_string_literal: true

require 'open3'

module RemoteRuby
  # An adapter to expecute Ruby code on a remote SSH server.
  # It will attempt tp write the code to a temporary file on the server and then execute.
  class SSHTmpFileAdapter < ::RemoteRuby::TmpFileAdapter
    include Open3

    attr_reader :server, :working_dir, :user, :key_file, :bundler

    def initialize(server:, working_dir: nil, user: nil, key_file: nil, bundler: false)
      super(working_dir: working_dir, bundler: bundler)
      @server = user.nil? ? server : "#{user}@#{server}"
      @user = user
      @key_file = key_file
    end

    protected

    def write_code_to_temp_file(code)
      popen3(ssh_command('f=$(mktemp) && cat > $f && echo $f')) do |stdin, stdout, stderr, wait_thr|
        stdin.write(code)
        stdin.close

        raise "Failed to create temporary file: #{stderr}" unless wait_thr.value.success?

        stdout.read.chomp
      end
    end

    def with_temp_file(code)
      fname = write_code_to_temp_file(code)
      yield fname
    ensure
      _, stderr, status = capture3(ssh_command("rm #{fname}"))
      warn "Failed to remove temporary file: #{stderr}" unless status.success?
    end

    def command(code_path)
      cmd = if bundler
              "cd \"#{working_dir}\" && bundle exec ruby #{code_path}"
            else
              "cd \"#{working_dir}\" && ruby #{code_path}"
            end

      ssh_command(cmd)
    end

    private

    def ssh_command(cmd)
      command = 'ssh'
      command = "#{command} -i #{key_file}" if key_file

      "#{command} #{server} '#{cmd}'"
    end
  end
end
