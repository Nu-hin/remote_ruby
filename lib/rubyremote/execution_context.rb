require 'open3'
require 'base64'
require 'method_source'
require 'colorize'
require 'rubyremote/compiler'

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
        compiler = Rubyremote::Compiler.new
        code = compiler.compile(ruby_code, id, **client_locals)
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
