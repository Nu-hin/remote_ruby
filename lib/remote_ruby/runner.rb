module RemoteRuby
  class Runner
    def initialize(code:, adapter:, out_stream: $stdout, err_stream: $stderr)
      @code = code
      @adapter = adapter
      @out_stream = out_stream
      @err_stream = err_stream
    end

    def run
      res = nil
      locals = nil

      adapter.open(code) do |stdout, stderr|
        stdout_thread = Thread.new do
          until stdout.eof?
            line = stdout.readline

            if line.start_with?('%%%MARSHAL')
              unmarshaler = RemoteRuby::Unmarshaler.new
              locals = unmarshaler.unmarshal(stdout)
              res = locals[:__return_val__]
            else
              out_stream.puts "#{adapter.connection_name.green}>\t#{line}"
            end
          end
        end

        stderr_thread = Thread.new do
          until stderr.eof?
            line = stderr.readline
            err_stream.puts "#{adapter.connection_name.red}>\t#{line}"
          end
        end

        stdout_thread.join
        stderr_thread.join
      end

      { result: res, locals: locals }
    end
  end

  private

  attr_reader :code, :adapter, :out_stream, :err_stream
end
