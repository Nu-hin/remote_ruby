# frozen_string_literal: true

require 'digest'
require 'fileutils'

require 'remote_ruby/compiler'
require 'remote_ruby/connection_adapter'
require 'remote_ruby/locals_extractor'
require 'remote_ruby/source_extractor'
require 'remote_ruby/flavour'
require 'remote_ruby/runner'

module RemoteRuby
  # This class is responsible for executing blocks on the remote host with the
  # specified adapters. This is the entrypoint to RemoteRuby logic.
  class ExecutionContext
    def initialize(**params)
      add_flavours(params)
      @use_cache = params.delete(:use_cache)   || false
      @save_cache = params.delete(:save_cache) || false
      @cache_dir = params.delete(:cache_dir)   || File.join(Dir.pwd, 'cache')
      @out_stream = params.delete(:out_stream) || $stdout
      @err_stream = params.delete(:err_stream) || $stderr
      @adapter_klass = params.delete(:adapter) || ::RemoteRuby::SSHStdinAdapter
      @params = params

      FileUtils.mkdir_p(@cache_dir)
    end

    def execute(locals = nil, &block)
      source = code_source(block)
      locals ||= extract_locals(block)

      result = execute_code(source, **locals)

      assign_locals(locals.keys, result[:locals], block)

      result[:result]
    end

    private

    attr_reader :params, :adapter_klass, :use_cache, :save_cache, :cache_dir,
                :out_stream, :err_stream, :flavours

    def assign_locals(local_names, values, block)
      local_names.each do |local|
        next unless values.key?(local)

        block.binding.local_variable_set(local, values[local])
      end
    end

    def extract_locals(block)
      extractor =
        ::RemoteRuby::LocalsExtractor.new(block, ignore_types: self.class)
      extractor.locals
    end

    def code_source(block)
      source_extractor = ::RemoteRuby::SourceExtractor.new
      source_extractor.extract(&block)
    end

    def context_hash(code_hash)
      Digest::MD5.hexdigest(
        self.class.name +
        adapter_klass.name.to_s +
        params.to_s +
        code_hash
      )
    end

    def cache_path(code_hash)
      hsh = context_hash(code_hash)
      File.join(cache_dir, hsh)
    end

    def cache_exists?(code_hash)
      hsh = cache_path(code_hash)
      File.exist?("#{hsh}.stdout") || File.exist?("#{hsh}.stderr")
    end

    def compiler(ruby_code, client_locals)
      RemoteRuby::Compiler.new(
        ruby_code,
        client_locals: client_locals,
        flavours: flavours
      )
    end

    def execute_code(ruby_code, client_locals = {})
      compiler = compiler(ruby_code, client_locals)

      runner = ::RemoteRuby::Runner.new(
        code: compiler.compiled_code,
        adapter: adapter(compiler.code_hash),
        out_stream: out_stream,
        err_stream: err_stream
      )

      runner.run
    end

    def adapter(code_hash)
      actual_adapter = adapter_klass.new(**params)

      if use_cache && cache_exists?(code_hash)
        cache_adapter(actual_adapter, code_hash)
      elsif save_cache
        caching_adapter(actual_adapter, code_hash)
      else
        actual_adapter
      end
    end

    def cache_adapter(adapter, code_hash)
      ::RemoteRuby::CacheAdapter.new(
        connection_name: adapter.connection_name,
        cache_path: cache_path(code_hash)
      )
    end

    def caching_adapter(adapter, code_hash)
      ::RemoteRuby::CachingAdapter.new(
        adapter: adapter,
        cache_path: cache_path(code_hash)
      )
    end

    def add_flavours(params)
      @flavours = ::RemoteRuby::Flavour.build_flavours(params)
    end
  end
end
