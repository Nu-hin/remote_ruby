# frozen_string_literal: true

require 'digest'
require 'fileutils'

require 'remote_ruby/compiler'
require 'remote_ruby/connection_adapter'
require 'remote_ruby/locals_extractor'
require 'remote_ruby/source_extractor'
require 'remote_ruby/plugin'
require 'remote_ruby/remote_context'
require 'remote_ruby/remote_error'
require 'remote_ruby/adapter_builder'

module RemoteRuby
  # This class is responsible for executing blocks on the remote host with the
  # specified adapters. This is the entrypoint to RemoteRuby logic.
  class ExecutionContext
    def initialize(**params)
      add_plugins(params)
      configure_streams(params)
      @dump_code = params.delete(:dump_code) || false
      @adapter_builder = RemoteRuby::AdapterBuilder.new(**params)
    end

    def execute(locals = nil, &block)
      source = code_source(block)
      locals ||= extract_locals(block)

      compiler = build_compiler(source, locals)
      context = execute_code(compiler)

      assign_locals(locals.keys, context.locals, block)

      if context.error?
        raise RemoteRuby::RemoteError.new(
          compiler.compiled_code,
          context,
          code_path(compiler.code_hash)
        )
      end

      context.result
    end

    private

    attr_reader :dump_code, :in_stream, :out_stream, :err_stream, :plugins, :adapter_builder

    def add_plugins(params)
      @plugins = ::RemoteRuby::Plugin.build_plugins(params)
    end

    def configure_streams(params)
      @in_stream = params.delete(:in_stream)         || $stdin
      @out_stream = params.delete(:out_stream)       || $stdout
      @err_stream = params.delete(:err_stream)       || $stderr
    end

    def extract_locals(block)
      extractor =
        ::RemoteRuby::LocalsExtractor.new(block, ignore_types: RemoteRuby.ignored_types)
      extractor.locals
    end

    def code_source(block)
      source_extractor = ::RemoteRuby::SourceExtractor.new
      source_extractor.extract(&block)
    end

    def build_compiler(ruby_code, client_locals)
      RemoteRuby::Compiler.new(
        ruby_code,
        client_locals: client_locals,
        plugins: plugins
      )
    end

    def execute_code(compiler)
      write_code(compiler.code_hash, compiler.compiled_code)

      adapter = adapter_builder.build(compiler.code_hash, out_tty: out_stream.tty?, err_tty: err_stream.tty?)

      # rubocop:disable Security/MarshalLoad
      Marshal.load(adapter.open(compiler.compiled_code, in_stream, out_stream, err_stream))
      # rubocop:enable Security/MarshalLoad
    end

    def assign_locals(local_names, values, block)
      local_names.each do |local|
        next unless values.key?(local)

        block.binding.local_variable_set(local, values[local])
      end
    end

    def code_path(code_hash)
      return nil unless dump_code

      File.join(RemoteRuby.code_dir, "#{code_hash}.rb")
    end

    def write_code(code_hash, code)
      return unless dump_code

      RemoteRuby.ensure_code_dir
      File.write(code_path(code_hash), code)
    end
  end
end
