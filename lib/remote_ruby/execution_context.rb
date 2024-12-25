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
    # rubocop:disable Metrics/CyclomaticComplexity
    def initialize(**params)
      add_flavours(params)
      @use_cache = params.delete(:use_cache)   || false
      @save_cache = params.delete(:save_cache) || false
      @cache_dir = params.delete(:cache_dir)   || File.join(Dir.pwd, 'cache')
      @in_stream = params.delete(:in_stream) || $stdin
      @out_stream = params.delete(:out_stream) || $stdout
      @err_stream = params.delete(:err_stream) || $stderr
      @adapter_klass = params.delete(:adapter) || ::RemoteRuby::SSHAdapter
      @text_mode = params.delete(:text_mode) || nil
      @params = params

      FileUtils.mkdir_p(@cache_dir)
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def execute(locals = nil, &block)
      source = code_source(block)
      locals ||= extract_locals(block)

      result = execute_code(source, **locals)

      assign_locals(locals.keys, result[:locals], block)

      result[:result]
    end

    private

    attr_reader :params, :adapter_klass, :use_cache, :save_cache, :cache_dir,
                :in_stream, :out_stream, :err_stream, :flavours, :text_mode

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
        in_stream: in_stream,
        out_stream: out_stream,
        err_stream: err_stream
      )

      runner.run
    end

    def adapter(code_hash)
      res = adapter_klass.new(**params)

      cache_mode = use_cache && cache_exists?(code_hash)

      res = if cache_mode
              cache_adapter(code_hash, res.connection_name)
            elsif save_cache
              caching_adapter(res, code_hash)
            else
              res
            end

      wrap_text_mode(res, cache_mode)
    end

    def wrap_text_mode(ad, cache_mode)
      return ad unless text_mode

      params = ::RemoteRuby::TextModeAdapter::DEFAULT_SETTINGS.merge(
        stdout_prefix: ad.connection_name,
        stderr_prefix: ad.connection_name,
        cache_used: cache_mode
      )

      params = params.merge(text_mode) if text_mode.is_a? Hash

      disable_unless_tty = params.delete(:disable_unless_tty)
      disable_unless_tty = true if disable_unless_tty.nil?

      params[:disable_stdout_prefixing] = true if disable_unless_tty && !out_stream.tty?
      params[:disable_stderr_prefixing] = true if disable_unless_tty && !err_stream.tty?

      return ad if params[:disable_stdout_prefixing] && params[:disable_stderr_prefixing]

      ::RemoteRuby::TextModeAdapter.new(ad, **params)
    end

    def cache_adapter(code_hash, connection_name)
      ::RemoteRuby::CacheAdapter.new(
        cache_path: cache_path(code_hash),
        connection_name: connection_name
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
