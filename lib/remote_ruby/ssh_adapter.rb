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
          ret = get_result(ssh, fname, res)
        end
      end
      ret
    end

    def run_code(ssh, fname, stdin_r, stdout_w, stderr_w)
      res = nil
      stdin_r = RemoteRuby::CompatIOReader.new(stdin_r)
      ssh.open_channel do |channel|
        channel.exec("cd '#{working_dir}' && ruby \"#{fname}\"") do |ch, success|
          raise UnableToExecuteError unless success

          ssh.listen_to(stdin_r.readable) do |io|
            data = io.read_nonblock(4096)
            ch.send_data(data)
          rescue EOFError
            ssh.stop_listening_to(stdin_r.readable)
            ch.eof!
          end

          ch.on_data do |_, data|
            stdout_w.write(data)
          end

          ch.on_extended_data do |_, _, data|
            stderr_w.write(data)
          end

          ch.on_request('exit-status') do |_, data|
            res = data.read_long
          end

          ch.on_close do
            ssh.stop_listening_to(stdin_r.readable)
          end
        end
      end.wait

      stdin_r.join
      res
    end

    def get_result(ssh, fname, process_status)
      raise "Process exited with code #{process_status}" unless process_status.zero?

      ssh.exec!("cat \"#{fname}\"")
    end

    def connection_name
      "#{user}@#{host}:#{working_dir || '~'}> "
    end

    def with_temp_file(code, ssh)
      fname = String.new
      ssh.open_channel do |channel|
        channel.exec('f=$(mktemp --tmpdir remote_ruby.XXXXXX) && cat > $f && echo $f') do |ch, success|
          raise UnableToExecuteError unless success

          ch.on_data do |_, data|
            fname << data
          end

          ch.send_data(code)
          ch.eof!
        end
      end.wait

      fname.strip!

      yield fname
    ensure
      Net::SSH.start(host, nil, config) do |del_ssh|
        del_ssh.exec!("rm \"#{fname}\"")
      end
    end
  end
end
