require 'method_source'
require 'colorize'
require 'rubyremote/compiler'
require 'rubyremote/connection_adapter'
require 'rubyremote/unmarshaler'

module Rubyremote
  class ExecutionContext
    def initialize(params = {})
      @adapter_name = params.delete(:adapter) || :ssh_stdin
      @params = params
    end

    def id
      self.hash.abs
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
      compiler = Rubyremote::Compiler.new
      code = compiler.compile(ruby_code, id, **client_locals)

      res = nil

      adapter = Rubyremote::ConnectionAdapter.build(adapter_name, params)

      adapter.open do |stdin, stdout, stderr|
        stdin.write(code)
        stdin.close

        until stdout.eof?
          line = stdout.readline

          if line.start_with?("%%%MARSHAL_#{id}")
            unmarshaler = Rubyremote::Unmarshaler.new
            locals = unmarshaler.unmarshal(stdout)
            res = locals["__return_val__#{id}"]
          else
            puts "#{adapter.connection_name.green}>\t#{line}"
          end
        end

        until stderr.eof?
          line = stderr.readline
          STDERR.puts "#{adapter.connection_name.red}>\t#{line}"
        end
      end

      res
    end

    private

    attr_reader :params, :adapter_name
  end
end
