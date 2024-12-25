require 'net/ssh'

module RemoteRuby
  class SSHAdapter < ConnectionAdapter
    attr_reader :host, :user, :config, :working_dir

    def initialize(host:, user: nil, working_dir: nil)
      super
      @host = host
      @working_dir = working_dir
      @config = Net::SSH.configuration_for(@host, true)
      @user = user || @config[:user]
    end

    def open(code)
      Net::SSH.start(host, user, config) do |ssh|
        with_temp_file(code, ssh) do |fname|
          stdout_r, stdout_w = IO.pipe
          stderr_r, stderr_w = IO.pipe
          stdin_r, stdin_w = IO.pipe

          t = Thread.new do
            ssh.open_channel do |channel|
              channel.exec("cd #{working_dir} && ruby #{fname}") do |ch, success|
                raise 'Could not execute command' unless success

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

                ch.on_close do |_|
                  stdout_w.close
                  stderr_w.close
                end
              end
            end.wait
          end

          @result_fname = stdout_r.readline.chomp
          yield stdin_w, stdout_r, stderr_r
          t.join
          @result = ssh.exec!("cat '#{@result_fname}'")
          ssh.exec!("rm #{@result_fname}")
        end
      end
    end

    def with_result_stream
      yield StringIO.new(@result)
    end

    def with_temp_file(code, ssh)
      fname = ''
      code_channel = ssh.open_channel do |channel|
        channel.exec('f=$(mktemp remote_ruby.rb.XXXXXX) && cat > $f && echo $f') do |ch, success|
          raise 'Could not execute command' unless success

          ch.on_data do |_, data|
            fname << data
          end

          ch.send_data(code)
          ch.eof!
        end
      end

      code_channel.wait

      yield fname
    ensure
      ssh.exec!("rm #{fname}")
    end
  end
end
