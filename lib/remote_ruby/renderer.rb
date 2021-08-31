# frozen_string_literal: true

require 'parser/current'

require 'remote_ruby/code_writer'
require 'remote_ruby/serializer'

module RemoteRuby
  # Compiles the client code along with all required variables, and adds
  # dependencies to provide a standalone ruby script
  class Renderer
    def render(ast, data)
      writer = ::RemoteRuby::CodeWriter.new

      render_requires(writer)
      writer.write_method(::RemoteRuby::Serializer.method(:deserialize), :__deserialize)
      render_data(writer, data)
      render_user_code(writer, ast)
      writer.close
      writer.string
    end

    private

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
      writer.write_section('client local variables') do |w|
        data.each do |name, value|
          value_encoded = ::RemoteRuby::Serializer.serialize(value)
          w.puts("#{name} = __deserialize('#{value_encoded}')")
        end
      end
    end

    def render_user_code(writer, ast)
      writer.write_section('user code') do |w|
        w.write_ast(ast)
      end
    end
  end
end
