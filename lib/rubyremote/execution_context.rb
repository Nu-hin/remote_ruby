require 'method_source'
require 'colorize'
require 'digest'

require 'rubyremote/compiler'
require 'rubyremote/connection_adapter'
require 'rubyremote/unmarshaler'

module Rubyremote
  class ExecutionContext
    def initialize(params = {})
      @use_cache = params.delete(:use_cache) || false
      @save_cache = params.delete(:save_cache) || false
      @cache_dir = params.delete(:cache_dir) || Dir.pwd
      @adapter_name = params.delete(:adapter) || :ssh_stdin
      @params = params
    end

    def execute(locals = {}, &block)
      execute_code(parse_block(block.source), **locals)
    end

    # Quick and dirty solution
    # Will only work with well-formatted 'do' blocks now
    def parse_block(block_code)
      block_code.lines[1..-2].join
    end

    def context_hash(code_hash)
      Digest::SHA256.hexdigest(self.class.name + adapter_name.to_s + params.to_s + code_hash)
    end

    def cache_path(code_hash)
      hsh = context_hash(code_hash)
      File.join(cache_dir, hsh)
    end

    def cache_exists?(code_hash)
      hsh = cache_path(code_hash)
      File.exist?("#{hsh}.stdout") || File.exist?("#{hsh}.stderr")
    end

    def execute_code(ruby_code, client_locals = {})
      compiler = Rubyremote::Compiler.new(ruby_code, **client_locals)
      code = compiler.compile

      res = nil

      code_hash = compiler.code_hash

      adapter = Rubyremote::ConnectionAdapter.build(adapter_name, params)

      adapter = if use_cache && cache_exists?(code_hash)
                  ::Rubyremote::CacheAdapter.new(
                    connection_name: adapter.connection_name,
                    cache_path: context_hash(code_hash)
                  )
                elsif save_cache
                  ::Rubyremote::CachingAdapter.new(
                    adapter: adapter,
                    cache_path: cache_path(code_hash)
                  )
                else
                  adapter
      end

      adapter.open do |stdin, stdout, stderr|
        stdin.write(code)
        stdin.close

        until stdout.eof?
          line = stdout.readline

          if line.start_with?('%%%MARSHAL')
            unmarshaler = Rubyremote::Unmarshaler.new
            locals = unmarshaler.unmarshal(stdout)
            res = locals['__return_val__']
          else
            $stdout.puts "#{adapter.connection_name.green}>\t#{line}"
          end
        end

        until stderr.eof?
          line = stderr.readline
          warn "#{adapter.connection_name.red}>\t#{line}"
        end
      end

      res
    end

    private

    attr_reader :params, :adapter_name, :use_cache, :save_cache, :cache_dir
  end
end
