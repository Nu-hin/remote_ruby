require 'open3'
require 'base64'
require 'method_source'
require 'colorize'

module Rubyremote
  class ExecutionContext
    attr_reader :server, :working_dir

    def initialize(server, working_dir)
      @server = server
      @working_dir = working_dir
    end

    def id
      self.hash.abs
    end

    def compile(ruby_code, client_locals = {})
      code = StringIO.new
      code.puts("require('base64')")

      if client_locals.any?
        code.puts "CLIENT_LOCALS_NAMES = %i(#{client_locals.keys.join(' ')})"
        code.puts "MARSHALLED_LOCALS_NAMES = CLIENT_LOCALS_NAMES + [:__return_val__#{id}]"
      end

      client_locals.each do |name, data|
        bin_data = Marshal.dump(data)
        base64_data = Base64.encode64(bin_data)
        code.puts <<-RUBY
          #{name} = begin
            Marshal.load(Base64.decode64('#{base64_data}'))
          rescue ArgumentError
            STDERR.puts("Warning: could not resolve type for #{name} variable")
            nil
          end
        RUBY
      end

      code.puts <<-RUBY
        __context_id__ = #{id}

        __return_val__#{id} = begin
          # Start of client code
          #{ruby_code}
          # End of client code
        end
      RUBY

      code.puts <<-'RUBY'
        # Marshalling local variables and result

        puts "%%%MARSHAL_#{__context_id__}"

        MARSHALLED_LOCALS_NAMES.each do |lv|
          data = Marshal.dump(eval(lv.to_s))
          data_length = data.size
          puts "#{lv}:#{data_length}"
          STDOUT.write(data)
        end
      RUBY

      code.string
    end

    def name
      "#{server}:#{working_dir}"
    end

    def execute(locals = {}, &block)
      execute_code(parse_block(block.source), **locals)
    end

    # Quick and dirty solution
    # Will only work with well-formatted 'do' blocks now
    def parse_block(block_code)
      block_code.lines[1..-2].join
    end

    def execute_code(ruby_code, client_locals = {})
      res = nil

      remote_command = "\"cd #{working_dir} && ruby\""
      command = "ssh #{server} #{remote_command}"

      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        code = compile(ruby_code, **client_locals)
        # puts code
        stdin.write(code)
        stdin.close

        until stdout.eof?
          line = stdout.readline
          locals = {}

          if line.start_with?("%%%MARSHAL_#{id}")
            until stdout.eof?
              line = stdout.readline
              varname, length = line.split(':')
              length = length.to_i
              data = stdout.read(length)

              begin
                locals[varname] = Marshal.load(data)
              rescue ArgumentError
                STDERR.puts("Warning: could not resolve type for #{varname} variable")
                locals[varname] = nil
              end
            end

            res = locals["__return_val__#{id}"]

            break
          else
            puts "#{name.green}>\t#{line}"
          end
        end

        until stderr.eof?
          line = stderr.readline
          STDERR.puts "#{name.red}>\t#{line}"
        end
      end

      res
    end
  end
end
