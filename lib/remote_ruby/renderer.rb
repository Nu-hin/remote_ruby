# frozen_string_literal: true

require 'parser/current'

require 'remote_ruby/code_writer'
require 'remote_ruby/serializer'
require 'remote_ruby/locals_extractor'

module RemoteRuby
  # Compiles the client code along with all required variables, and adds
  # dependencies to provide a standalone ruby script
  class Renderer
    def render(ast, data)
      writer = ::RemoteRuby::CodeWriter.new

      render_requires(writer)
      render_methods(writer)
      render_data(writer, data)
      render_user_code(writer, ast)
      writer.close
      writer.string
    end

    private

    def render_methods(writer)
      methods = {
        __deserialize: ::RemoteRuby::Serializer.instance_method(:deserialize),
        __assign_locals: ::RemoteRuby::LocalsExtractor.method(:assign)
      }

      writer.write_section('methods required by RemoteRuby') do |w|
        methods.each do |name, method|
          w.write_method(method, name)
          w.puts
        end
      end
    end

    def render_file(writer, fname)
      path = File.join(__dir__, '..', fname)
      contents = File.read(path)

      writer.write_section(fname) do |w|
        w.write(contents)
      end
    end

    def render_requires(writer)
      writer.write_section('RemoteRuby dependencies') do |w|
        %w[stringio base64 zlib].each do |lib|
          w.write_require(lib)
        end
      end
    end

    def render_data(writer, data)
      serializer = ::RemoteRuby::Serializer.new
      data_base64 = serializer.serialize(data)

      writer.write_section('client local variables') do |w|
        w.puts("__client_locals__ = __deserialize('#{data_base64}')")
        w.puts('__assign_locals(binding, __client_locals__)')
      end
    end

    def render_user_code(writer, ast)
      writer.write_section('user code') do |w|
        w.write_ast(ast)
      end
    end
  end
end
