require 'open3'
# require 'parse_tree'
# require 'parse_tree_extensions'
require 'method_source'

module Rubyremote
  class ExecutionContext
    attr_reader :server

    def initialize(server)
      @server = server
    end

    def id
      self.hash.abs
    end

    def compile(ruby_code)
      <<-RUBY
        __return_val__#{id} = begin
          # Start of client code
          #{ruby_code}
          # End of client code
        end

        # Marshalling local variables and result
        lv_hash = Hash[local_variables.map do |lv|
          [lv.to_s, eval(lv.to_s)]
        end]

        puts "%%%MARSHAL_#{id}"
        STDOUT.write(Marshal.dump(lv_hash))
      RUBY
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

      Open3.popen3('ssh', server, 'ruby') do |stdin, stdout, stderr, wait_thr|
        code = compile(ruby_code)
        # puts code

        stdin.write(code)
        stdin.close

        until stdout.eof?
          line = stdout.readline

          if line.start_with?("%%%MARSHAL_#{id}")
            rest = stdout.read
            locals = Marshal.load(rest)
            res = locals["__return_val__#{id}"]

            break
          else
            puts line
          end
        end

        STDERR.write(stderr.read)
      end

      res
    end
  end
end
