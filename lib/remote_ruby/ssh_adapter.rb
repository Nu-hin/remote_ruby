# frozen_string_literal: true

require 'net/ssh'
require 'remote_ruby/pipes'

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

    def open(code)
      Net::SSH.start(host, nil, config) do |ssh|
        with_temp_file(code, ssh) do |fname|
          Pipes.with_pipes do |p|
            t = Thread.new do
              res = run_code(ssh, fname, p.in_r, p.out_w, p.err_w)
              get_result(ssh, fname, p.res_w, res)
            end

            yield p.in_w, p.out_r, p.err_r, p.res_r
            t.join
          end
        end
      end
    end

    def run_code(ssh, fname, stdin_r, stdout_w, stderr_w)
      res = nil
      ssh.open_channel do |channel|
        channel.exec("cd '#{working_dir}' && ruby \"#{fname}\"") do |ch, success|
          raise UnableToExecuteError unless success

          ssh.listen_to(stdin_r) do |io|
            data = io.read_nonblock(4096)
            ch.send_data(data)
          rescue EOFError
            ch.eof!
          end

          ch.on_data do |_, data|
            stdout_w << data
          end

          ch.on_extended_data do |_, _, data|
            stderr_w << data
          end

          ch.on_request('exit-status') do |_, data|
            res = data.read_long
          end

          ch.on_close do |_|
            stdout_w.close
            stderr_w.close
          end
        end
      end.wait
      res
    end

    def get_result(ssh, fname, res_w, process_status)
      unless process_status.zero?
        res_w.close
        raise "Process exited with code #{process_status}"
      end

      ssh.open_channel do |channel|
        channel.exec("cat \"#{fname}\"") do |ch, success|
          raise UnableToExecuteError unless success

          ch.on_data do |_, data|
            res_w << data
          end

          ch.on_close do |_|
            res_w.close
          end
        end
      end.wait
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
