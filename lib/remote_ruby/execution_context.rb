# frozen_string_literal: true

require 'digest'
require 'fileutils'

require 'remote_ruby/compiler'
require 'remote_ruby/connection_adapter'
require 'remote_ruby/locals_extractor'
require 'remote_ruby/source_extractor'
require 'remote_ruby/plugin'
require 'remote_ruby/runner'
require 'remote_ruby/remote_error'

module RemoteRuby
  # This class is responsible for executing blocks on the remote host with the
  # specified adapters. This is the entrypoint to RemoteRuby logic.
  class ExecutionContext
    def initialize(**params)
      add_plugins(params)
      chose_adapter_klass(params)
      configure_cache(params)
      configure_streams(params)
      @text_mode = params.delete(:text_mode)         || false
      @code_dump_dir = params.delete(:code_dump_dir) || nil
      @adapter_params = params

      FileUtils.mkdir_p(@cache_dir)
    end

    def execute(locals = nil, &block)
      source = code_source(block)
      locals ||= extract_locals(block)

      compiler = compiler(source, locals)
      context = execute_code(compiler)

      assign_locals(locals.keys, context.locals, block)

      if context.error?
        raise RemoteRuby::RemoteError.new(
          compiler.compiled_code,
          context,
          code_dump_path(compiler.code_hash)
        )
      end

      context.result
    end

    private

    attr_reader :adapter_params, :adapter_klass, :use_cache, :save_cache, :cache_dir,
                :in_stream, :out_stream, :err_stream, :plugins, :text_mode, :code_dump_dir

    def configure_cache(params)
      @use_cache = params.delete(:use_cache)         || false
      @save_cache = params.delete(:save_cache)       || false
      @cache_dir = params.delete(:cache_dir)         || File.join(Dir.pwd, '.remote_ruby', 'cache')
    end

    def configure_streams(params)
      @in_stream = params.delete(:in_stream)         || $stdin
      @out_stream = params.delete(:out_stream)       || $stdout
      @err_stream = params.delete(:err_stream)       || $stderr
    end

    def chose_adapter_klass(params)
      @adapter_klass = params.delete(:adapter)
      return unless @adapter_klass.nil?

      @adapter_klass = if params[:host]
                         ::RemoteRuby::SSHAdapter
                       else
                         ::RemoteRuby::TmpFileAdapter
                       end
    end

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
        adapter_params.to_s +
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
        plugins: plugins
      )
    end

    def execute_code(compiler)
      dump_code(compiler.code_hash, compiler.compiled_code)

      runner = ::RemoteRuby::Runner.new(
        code: compiler.compiled_code,
        adapter: adapter(compiler.code_hash),
        in_stream: in_stream,
        out_stream: out_stream,
        err_stream: err_stream
      )

      runner.run
    end

    def code_dump_path(code_hash)
      return nil unless code_dump_dir

      File.join(code_dump_dir, "remote_ruby_#{code_hash}.rb")
    end

    def dump_code(code_hash, code)
      return unless code_dump_dir

      File.write(code_dump_path(code_hash), code)
    end

    def adapter(code_hash)
      res = adapter_klass.new(**adapter_params)

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

    def text_mode_params(adapter, cache_mode)
      tm_params = ::RemoteRuby::TextModeAdapter::DEFAULT_SETTINGS.merge(
        stdout_prefix: adapter.connection_name,
        stderr_prefix: adapter.connection_name
      )

      tm_params = tm_params.merge(text_mode) if text_mode.is_a? Hash

      disable_unless_tty = tm_params.delete(:disable_unless_tty) { |_| true }

      tm_params[:stdout_prefix] = nil if disable_unless_tty && !out_stream.tty?
      tm_params[:stderr_prefix] = nil if disable_unless_tty && !err_stream.tty?
      tm_params[:cache_prefix] = nil unless cache_mode
      tm_params
    end

    def wrap_text_mode(adapter, cache_mode)
      return adapter unless text_mode

      tm_params = text_mode_params(adapter, cache_mode)

      return adapter unless tm_params[:stdout_prefix] || tm_params[:stderr_prefix]

      ::RemoteRuby::TextModeAdapter.new(adapter, **tm_params)
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

    def add_plugins(params)
      @plugins = ::RemoteRuby::Plugin.build_plugins(params)
    end
  end
end
