require 'open3'
# require 'parse_tree'
# require 'parse_tree_extensions'
require 'method_source'

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

    def compile(ruby_code)
      body = <<-RUBY
        __context_id__ = #{id}

        __return_val__#{id} = begin
          # Start of client code
          #{ruby_code}
          # End of client code
        end
      RUBY

      footer = <<-'RUBY'
        # Marshalling local variables and result

        puts "%%%MARSHAL_#{__context_id__}"

        local_variables.each do |lv|
          data = Marshal.dump(eval(lv.to_s))
          data_length = data.size
          puts "#{lv}:#{data_length}"
          STDOUT.write(data)
        end
      RUBY

      body + footer
    end

    def execute(&bl)
      execute_code(parse_block(bl.source))
    end

    # Quick and dirty solution
    # Will only work with well-formatted 'do' blocks now
    def parse_block(block_code)
      block_code.lines[1..-2].join
    end

    def execute_code(ruby_code)
      res = nil

      remote_command = "\"cd #{working_dir} && ruby\""
      command = "ssh #{server} #{remote_command}"

      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        code = compile(ruby_code)

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
                locals[varname] = nil
              end
            end

            res = locals["__return_val__#{id}"]

            break
          else
            puts "> #{line}"
          end
        end

        STDERR.write(stderr.read)
      end

      res
    end
  end
end
