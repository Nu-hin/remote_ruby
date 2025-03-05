# frozen_string_literal: true

require 'net/ssh'
require 'remote_ruby/compat_io_reader'

module RemoteRuby
  # An adapter for executing Ruby code on a remote host via SSH
  class SSHAdapter < ConnectionAdapter
    UnableToExecuteError = Class.new(StandardError)

    attr_reader :host, :config, :working_dir, :user

    def initialize(host:, working_dir: nil, use_ssh_config_file: true, **params)
      super
      @host = host
      @working_dir = working_dir
      @config = Net::SSH.configuration_for(@host, use_ssh_config_file)

      @config = @config.merge(params)
      @user = @config[:user]
    end

    def open(code, stdin, stdout, stderr)
      ret = nil
      Net::SSH.start(host, nil, config) do |ssh|
        with_temp_file(code, ssh) do |fname|
          res = run_code(ssh, fname, stdin, stdout, stderr)
          raise "Process exited with code #{status}" unless res.zero?

          ret = get_result(ssh, fname)
        end
      end
      ret
    end

    def connection_name
      "#{user}@#{host}:#{working_dir || '~'}> "
    end

    private

    def handle_stdin(chan, stdin)
      return if stdin.nil?

      if stdin.is_a?(StringIO)
        chan.send_data(stdin.string)
        chan.eof!
        return
      end

      stdin = RemoteRuby::CompatIOReader.new(stdin)

      chan.connection.listen_to(stdin.readable) do |io|
        data = io.read_nonblock(4096)
        chan.send_data(data)
      rescue EOFError
        chan.connection.stop_listening_to(stdin.readable)
        chan.eof!
      end

      chan.on_close do
        chan.connection.stop_listening_to(stdin.readable)
        stdin.join
      end
    end

    def handle_stdout(chan, stdout)
      return if stdout.nil?

      chan.on_data do |_, data|
        stdout.write(data)
      end
    end

    def handle_stderr(chan, stderr)
      return if stderr.nil?

      chan.on_extended_data do |_, _, data|
        stderr.write(data)
      end
    end

    def handle_exit_code(chan)
      chan.on_request('exit-status') do |_, data|
        yield data.read_long
      end
    end

    def run_remote_process(ssh, cmd, stdin, stdout, stderr)
      res = nil

      ssh.open_channel do |channel|
        channel.exec(cmd) do |ch, success|
          raise UnableToExecuteError unless success

          handle_stdin(ch, stdin)
          handle_stdout(ch, stdout)
          handle_stderr(ch, stderr)
          handle_exit_code(ch) do |code|
            res = code
          end
        end
      end.wait

      res
    end

    def run_code(ssh, fname, stdin, stdout, stderr)
      run_remote_process(ssh, "cd '#{working_dir}' && ruby \"#{fname}\"", stdin, stdout, stderr)
    end

    def get_result(ssh, fname)
      ssh.exec!("cat \"#{fname}\"")
    end

    def with_temp_file(code, ssh)
      out = StringIO.new
      cmd = 'f=$(mktemp --tmpdir remote_ruby.XXXXXX) && cat > $f && echo $f'
      run_remote_process(ssh, cmd, StringIO.new(code), out, nil)
      fname = out.string.strip

      yield fname
    ensure
      ssh.exec!("rm \"#{fname}\"")
    end
  end
end
